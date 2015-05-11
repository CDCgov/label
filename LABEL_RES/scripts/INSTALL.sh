#!/bin/bash
# INSTALLATION TOOL for LABEL.
# Sam Shepard, 2012

if [ -x "`which uname`" ];then
	OS=`uname -s`
	ARCH=`uname -m`
else
	#OS="Darwin"
	OS="Linux"
	ARCH="x86_64"
fi

bin=binaries_and_licenses
shogun=shogun1.1.0_cmdline_static
sam=sam3.5/bin
muscle=muscle3.8.31
fasttree=fasttree2.1.4

echo "$0: Unlinking current binaries."
rm ./muscle ./hmmscore ./FastTreeMP ./shogun ./modelfromalign ./align2model

if [ $OS == "Darwin" ];then
	echo "$0: Linking DARWIN binaries."
	ln -s $bin/$fasttree/FastTreeMP_darwin64 FastTreeMP
	ln -s $bin/$muscle/muscle3.8.31_darwin64 muscle
	ln -s $bin/$sam/hmmscore_darwin64 hmmscore
	ln -s $bin/$sam/modelfromalign_darwin64 modelfromalign
	ln -s $bin/$shogun/shogun_darwin64 shogun
	ln -s $bin/$sam/align2model_darwin64 align2model
elif [ $OS == "Linux" ];then
	if [ $ARCH == "x86_64" ];then
		echo "$0: Linking LINUX 64-bit binaries."
		ln -s $bin/$fasttree/FastTreeMP_linux64 FastTreeMP
		ln -s $bin/$muscle/muscle3.8.31_linux64 muscle
		ln -s $bin/$sam/hmmscore_linux64 hmmscore
		ln -s $bin/$sam/modelfromalign_linux64 modelfromalign
		ln -s $bin/$shogun/shogun_linux64 shogun
		ln -s $bin/$sam/align2model_linux64 align2model
	else
		echo "$0: Linking LINUX 32-bit binaries."
		ln -s $bin/$fasttree/FastTreeMP_linux32 FastTreeMP
		ln -s $bin/$muscle/muscle3.8.31_linux32 muscle
		ln -s $bin/$sam/hmmscore_linux32 hmmscore
		ln -s $bin/$sam/modelfromalign_linux32 modelfromalign
		ln -s $bin/$shogun/shogun_linux32 shogun
		ln -s $bin/$sam/align2model_linux32 align2model
	fi
else
	echo "$0: Unknown OS ($OS, $ARCH)."
	echo "$0: Linux & Darwin (Mac) are valid."
	echo "$0: Your OS has not been tested."
	echo "$0: Try using Linux if you have a unix system."
fi
