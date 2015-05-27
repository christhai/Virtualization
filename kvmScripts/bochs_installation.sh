# Upgrade packages to solve dependencies

PREFIX=/usr/local

bochs_version="2.6.6"
bochs_link="http://downloads.sourceforge.net/project/bochs/bochs/2.6.6/bochs-2.6.6.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fbochs%2Ffiles%2Fbochs%2F2.6.6%2F&ts=1410367455&use_mirror=heanet"

bochs_file="bochs-$bochs_version.tar.gz"

# Create a directory (update this path if you don't like the location)
mkdir -p $PREFIX/src/
cd $PREFIX/src
wget -c --trust-server-name $bochs_link 
tar -xf bochs*.gz



# Bochs configuration:
# - Enable the internal debugger
# - Use X graphics; works over terminal
# - Enable USB (might be useful for USB-stick support)
# - Enable disassembly; sounded useful for assembly-parts of IncludeOS
cd bochs-$bochs_version
./configure --enable-debugger --with-x11 --enable-usb --enable-disasm 

# - I also tried using sdl-graphics for GUI (Ubuntu doesn't use X anymore):
#./configure --enable-debugger --with-sdl --enable-usb --enable-disasm 
# ... But this caused a linking error, so switched to x11, which works fine after all

# LIBS =  -lgtk-x11-2.0 -lgdk-x11-2.0 -latk-1.0 -lgio-2.0 -lpangoft2-1.0 -lpangocairo-1.0 -lgdk_pixbuf-2.0 -lcairo -lpango-1.0 -lfontconfig -lgobject-2.0 -lglib-2.0 -lfreetype -lp$

cat Makefile | sed s/lfreetype/"lfreetype -lpthread"/ > Makefile.tmp
cp Makefile.tmp Makefile

#PATCH Makefile:
#echo "NOW UPDATE MAKEFILE: (then type anything except EOF to continue)"
#echo "Under 'LIBS', add '-lpthread'"
#echo "(Ref.: http://askubuntu.com/questions/376204/bochs-compiling-error-again)"
#read INPUT

make
sudo make install

echo -e "\nDONE! (hopefully)\n"
