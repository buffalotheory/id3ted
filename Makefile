all: id3ted

CXX?=g++
PREFIX?=/usr/local
CXXFLAGS+= -I$(PREFIX)/include -Wall -pedantic
LDFLAGS+= -L$(PREFIX)/lib
LIBS+= -ltag -lmagic

CPPFILES=$(wildcard *.cpp)
OBJFILES=$(CPPFILES:.cpp=.o)

id3ted:	$(OBJFILES)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LIBS)

%.o: %.cpp Makefile
	$(CXX) $(CXXFLAGS) -c -o $@ $<

install: all
	install -D -m 0755 id3ted $(DESTDIR)$(PREFIX)/bin/id3ted

clean:
	rm -f id3ted *.o

tags: *.h *.cpp
	ctags $^

cscope: *.h *.cpp
	cscope -b

test: id3ted
	./test_tag_write_verify_all.sh 2>&1 | grep -i "failed\|complete"
