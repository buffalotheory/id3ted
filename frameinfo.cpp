/* id3ted: frameinfo.cpp
 * Copyright (c) 2011 Bert Muennich <be.muennich at googlemail.com>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

#include <cstring>
#include <cstdio>

#include "fileio.h"
#include "frameinfo.h"
#include "options.h"

FrameInfo::FrameInfo(const char *id, ID3v2FrameID fid, const char *text) :
		_id(id), _fid(fid), _text(text, DEF_TSTR_ENC),
		_description(), _language("XXX"), _data()
{
	switch (_fid) {
		case FID3_APIC: {
			IFile file(text);
			const char *mimetype;

			if (!file.isOpen())
				break;
			mimetype = FileIO::mimetype(text);
			if (strstr(mimetype, "image") == NULL) {
				warn("%s: Wrong mime-type: %s. Not an image, not attached.", text,
				     mimetype);
				break;
			}
			file.read(_data);
			if (file.error())
				_data.clear();
			else
				_description = mimetype;
			break;
		}
		case FID3_COMM:
		case FID3_USLT:
			split3();
			break;
		case FID3_TXXX:
		case FID3_WXXX:
			split2();
			break;
		default:
			break;
	}
}

void FrameInfo::split2() {
	int idx, len;

	idx = _text.find(Options::fieldDelimiter, 0);
	if (idx != -1) {
		len = idx++;
		_description = _text.substr(idx, _text.length() - len);
		_text = _text.substr(0, len);
	}
}

void FrameInfo::split3() {
	int idx, len;

	split2();
	if (!_description.isEmpty()) {
		idx = _description.find(Options::fieldDelimiter, 0);
		if (idx != -1) {
			len = idx++;
			if (_description.length() - idx == 3)
				_language = _description.substr(idx, 3).data(DEF_TSTR_ENC);
			_description = _description.substr(0, len);
		}
	}
}
