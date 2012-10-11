#!/bin/bash
## Configuration ##

# By default, your quota is 10,000 files, or current number*2, whatever is higher.
# This will control how many temporary files are created.
# If you want your new limit to be 15,000 files, set this to 7,500. Etc.
# This is the default behaviour. You can change it as you see fit.
# Run `quota` to view your current limits.
files_to_create=7500

# Your quota is also dependent on where the files are located.
# eg, your file count limit is different for your home directory
# and web publishing directory.
# By default, it will create these extra files in your home directory.
cd ~
# If you want to make it use your web publishing directory instead, uncomment out this line
# cd `wwwhome`


# Time to begin!

# Create temporary directory.
mkdir temp_hacky_hack
cd temp_hacky_hack
let "count=0"
echo -e "\nCreating $files_to_create files, this may take a while..."
while [ $count != $files_to_create ]
do
  #Uncomment this out if you want a count, just to see what's happening.
  # echo "touching file $count"
  touch temp_hacky_hack-$count
  ((count+=1))
done
adjquota
echo -e "\nFiles created! Now I'm deleting the temp ones. Please hold."
cd ..
rm -r temp_hacky_hack
echo "All Done! Don't run adjquota unless you want to reset your limits."

