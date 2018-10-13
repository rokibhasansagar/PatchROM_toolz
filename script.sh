#!/bin/bash

# Authors - 
#   Neil "regalstreak" Agarwal,
#   Harsh "MSF Jarvis" Shandilya,
#   Tarang "DigiGoon" Kagathara
# -----------------------------------------------------
# Modified by - Rokib Hasan Sagar @rokibhasansagar
# -----------------------------------------------------

# Definitions
DIR=$(pwd)
echo -en "Current directory is -- " && echo $DIR

PatchCode=$1
LINK=$2
BRANCH=$3
GitHubMail=$4 && GitHubName=$5
FTPHost=$6 && FTPUser=$7 && FTPPass=$8

echo -e "Making Update and Installing Apps"
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install pxz wput -y

echo -e "ReEnable PATH and Set Repo & GHR"
mkdir ~/bin ; echo ~/bin || echo "bin folder creation error"
sudo curl --create-dirs -L -o /usr/local/bin/repo -O -L https://github.com/akhilnarang/repo/raw/master/repo
sudo cp .circleci/ghr ~/bin/ghr
sudo chmod a+x /usr/local/bin/repo
PATH=~/bin:/usr/local/bin:$PATH

echo -e "Github Authorization"
git config --global user.email $GitHubMail
git config --global user.name $GitHubName
git config --global color.ui true

echo -e "Main Function Starts HERE"
cd $DIR; mkdir $PatchCode; cd $PatchCode

echo -e "Initialize the Repo to Fetch the Data"
repo init -q -u $LINK -b $BRANCH --depth 1 || repo init -q -u $LINK --depth 1

echo -e "Syncing it up"
time repo sync -c -f -q --force-sync --no-clone-bundle --no-tags -j32
echo -e "\nSource Syncing done\n"

# Show Total Sizes of .repo and then Delete it
echo -en "The total size of the .repo folder is ---  "
du -sh .repo/ | awk '{print $1}'
echo -e "Deleting unnecessary .repo folder"
rm -rf .repo/

echo -e "Removing the residual .git folders from all subfolders"
find . | grep .git | xargs rm -rf

# Show and Record Total Sizes of the checked-out non-repo files
cd $DIR
echo -en "The total size of the checked-out files is ---  " && du -sh $PatchCode

cd $PatchCode

# Compress non-repo folder in one piece
echo -e "Compressing files --- "
echo -e "Please be patient, this will take time"

mkdir -p ~/project/files/

export XZ_OPT=-9e

time tar -I pxz -cf ~/project/files/$PatchCode-$BRANCH-files-$(date +%Y%m%d).tar.xz *
echo -en "Final Compressed size of the consolidated checked-out archive is ---  "
du -sh ~/project/files/$PatchCode-$BRANCH-files*.tar.xz

echo -e "Compression Done"

cd ~/project/files

# Take md5
md5sum $PatchCode-$BRANCH-files* > $PatchCode-$BRANCH-files-$(date +%Y%m%d).md5sum
cat $PatchCode-$BRANCH-files-$(date +%Y%m%d).md5sum

# Make a Compressed file list for future reference
tar -tJvf *.tar.xz | awk '{print $6}' >> $PatchCode-$BRANCH-files-$(date +%Y%m%d).list
tar -I pxz -cf $PatchCode-$BRANCH-files.list.tar.xz *.list
rm *.list

# Show Total Sizes of the compressed files
echo -en "Final Compressed size of the checked-out files is ---  "
du -sh ~/project/files/

cd $DIR
# Basic Cleanup
rm -rf $PatchCode

cd ~/project/files/

echo -e "Upload the Package to AFH"
for file in $PatchCode-$BRANCH*; do wput $file ftp://"$FTPUser":"$FTPPass"@"$FTPHost"//$PatchCode-NoRepo/ ; done

echo -e "Upload the Package to transfer.sh"
for file in $PatchCode-$BRANCH*; do curl --upload-file $file https://transfer.sh/ && echo '' ; done

echo -e "GitHub Release"
cd ~/project/
ghr -u $GitHubName -t $GITHUB_TOKEN -b 'Releasing The Necessary File Package for PatchROM' -n 'Compressed Files for $PatchCode' $PatchCode ~/project/files/

echo -e "\nCongratulations! Job Done!"
