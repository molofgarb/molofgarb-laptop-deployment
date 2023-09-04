# Laptop Setup Scripts

Table of Contents:
- Laptop Setup Scripts -- How to Use
- Important Notes
- Latitude 5320 - Laptop_Setup_prep.bat
- Latitude 5320 - Laptop_Setup_update.bat
- Latitude 5320 - User_Setup_create.bat
- Latitude 5320 - User_Setup_configure.bat

## Laptop Setup Scripts -- How to Use

The contents of this directory should be placed on an external drive (USB drive)
and the script should be run directly from the USB drive. It is not recommended
to run the script from the system drive, but nothing other than maybe BitLocker
recovery password storage should break if you do. It is recommended that you
run this script from the same drive that holds Clonezilla images for the device
being set up so that you can start the script immediately after imaging has finished.
For example, the path to this folder should be something like:
D:\Laptop_Setup\
  - NOTE: There have been issues in the past with running the script in a path
    that has a space in its name (e.g. D:\Laptop Setup). This issue should be fixed,
    but if the script has behaving oddly, try running it from a path with no spaces.

To start the script, run (double-click in File Explorer) a main menu script in
this directory. Main menu scripts are usually named <device_name>_Setup.bat.
As of 8/15/2023, the only main menu script is Latitude_5320_Setup.bat. Once you
launch the script, use the keyboard to select the task that you would like to
perform.
  - To launch a script, type the number 1-9 corresponding to the script that
    you want to execute and then press enter. This will execute the script that
    you have selected. For example, if you entered the number corresponding
    to "Prepare Laptop", then the laptop preparation script will begin.
  - To perform a misc. task, type the letter a, s, d, f, etc. corresponding
    to the task that you want to perform and then press enter. This will perform
    the task that you chose. For example, if you entered the letter corresponding
    to "Clear logs directory", then all files in the logs directory will be deleted.

The setup scripts will walk you through the setup process step-by-step. All dependencies
for the setup process are provided with a clean clone of this root directory or will
be acquired by the script. The dependencies that are provided with the script are
found in the lib folder. The dependencies that are downloaded by the script are found
in the installers folder.

All script logs can be found in the logs directory. The scripts will log all events 
to a file with the service tag of the corresponding device as the name of the log. 
For example, if the device is 57HCRL3, then the log will be called 57HCRL3.log. 
Logs are also generated for Dell Command Update, the KMS, Firefox, Chrome, and Zoom
with names like <service_tag>_Zoom.log.

A clean clone of this directory does not include the logs and installers directory.
The setup scripts will generate these directories when needed.

Fast mode in the script will automatically continue when the script presents
the "Press space to continue the script. . ." prompt. The script will still stop
when you are asked for a specific input (1, 2, 3, y, n, etc.) or when you are asked
to confirm something ("Press y to confirm. . .").

The local logging feature will only generate local logs for local accounts with
admin privileges. If you are logged in as a non-privileged user, no actions are
kept in a local log until the script is escalated to have admin privileges. Then,
the script generates a local log in the Desktop of the admin that the script is
running as.

## Important Notes

You should be familiar with the manual configuration process before
you use the script so that you know exactly what changes the script is performing
and can identify any bugs in case the script fails. It is also handy to know these
setup instructions in case you need to prep a new device model and aren't sure if
the script will work properly with the new model.

The script may sometimes freeze or present you with a completely blank screen.
This is a bug with batch scripts.
  - To work around this issue, select the script window with your cursor
    and press the space key. You may need to press the space key several times.
    Eventually, the script will display the proper interface and continue.

While the script is performing a task like registry changes or an update installation,
it will store any inputs that you enter and then apply those inputs after it is done
with that task. For example, if you press the space key three times during an
installation task, then the script may skip three messages after the installation
task is finished.
  - To avoid this issue, please only send inputs when the script asks you to do
    so and please only send one input at a time (don't spam the keyboard).

When the script prompts you "Press space to continue the script. . .", please
only press alphanumeric characters, the space bar, or the enter key. Pressing
other characters (like the arrow keys) may cause the script to behave unpredictably.
  - To avoid this issue, please **only use the space key to continue**.

When entering a password, avoid pressing the backspace key because it may sometimes
erase more than one character when you have special characters in your password.
  - To avoid this issue, please **do not use the backspace key for password input**.
    If you input the wrong character, please press Enter and input the password starting
    from the beginning again.

If Dell Command | Update has installed all updates and wants you to restart your
device, then the Dell Command | Update CLI call in the update script will generate
an empty DCU log file and return an error.
  - To avoid this issue, restart the computer if you encounter this bug. The restart
    will apply all updates and the update script will function normally (allow you
    to progress after DCU CLI) after all DCU updates are fully installed.

Sometimes the installation of Firefox may fail and produce no error logs. It is
difficult to figure out why because there are no logs, but it could be because the
Firefox .msi installer uses a non-standard msiexec argument format.
  - To workaround this issue, the script will try to install Firefox again.

Please make sure to read the script's instructions carefully.

## Latitude 5320 - Laptop_Setup_prep.bat

This script prepares the system configuration of a laptop before deployment to
a user. This script should be run from an admin account.

This script can be run on a freshly imaged laptop or on a returned laptop that
had already been prepped. The script will automatically skip or allow you to skip
certain sections that are specific to freshly imaged laptops, like Microsoft Office
licensing and BitLocker.

If Microsoft Office is already licensed, then the script will skip the KMS installation
step.

If BitLocker is enabled and on, then the script will skip all BitLocker steps. 
  - The script will run the BitLocker sections if BitLocker is enabled but off -- 
  this is the case when the drive is unencrypted but there exists a PIN and recovery 
  password for the drive when BitLocker is turned on. New BitLocker protectors are
  made and applied in case the old protectors had been lost (the recovery password
  file was never saved).

### Table of Contents:
- Check Admin
- Check Internet
- Check Date and Time
- Input: Department
- Start KMS
- Set Computer Name
- Disable Windows 11 Upgrade
- Set Local Accounts by Department
- Check Microsoft Office Licensing
- Revert to OEM Windows License
- BitLocker PIN Generation
- Turn On BitLocker
- BitLocker Local Group Policies
- BitLocker Recovery Password File Generation
- Set Default User Programs Globally
- BIOS Instructions

After this script has finished, it will return you to the main menu.

## Latitude 5320 - Laptop_Setup_update.bat

This script updates Windows, Dell Command Update, Firefox, Chrome, and Zoom on a
laptop. This script should be run from an admin account.

### Table of Contents:
- Check Admin
- Check Internet
- Begin Windows Update
- Dell Command Update
- Firefox Update
- Chrome Update
- Zoom Update
- Windows Update Check

After this script has finished, it will ask if you would like to restart or return
to the main menu.

## Latitude 5320 - User_Setup_create.bat

This script creates a local user on the laptop. This script should be run from an 
admin account.

### Table of Contents:
- Check Admin
- Input: Username
- Input: Fullname
- User Creation Confirmation
- User Creation

After this script has finished, it will ask if you would like to log out of the
current user or return to the main menu.

## Latitude 5320 - User_Setup_configure.bat

This script configures a local user's environment to match a set of specifications.
This script should be run from **the user whose environment is being configured**,
which is usually the user account set up in User_Setup_create.bat. You should log
in as that user and run the script while logged in as that user.

### Table of Contents:
- Check Admin
- Input: Local Group Policy Update Interval
- Set Default Applications
- Set Firefox to Not Ask to be Default
- Set Microsoft Word to Install Updates Only
- Disable First-Run Experience and Default Browser Prompt in Edge
- Disable OneDrive from Running on Startup
- Dismiss Windows Security Warnings
- Disable Sign-In Info to Finish Device Setup After an Update
- Set Search Bar to be Hidden
- Set Cortana to be Hidden
- Set Taskbar Shortcuts
- Set Notification Settings
- Update Local Group Policy, Registry, and Explorer Desktop Environment

After this script has finished, it will ask if you would like to log out of the
current user or return to the main menu.

# How to Modify/Contribute/Maintain the Scripts

The contents in this section are notes for developers that need to modify or 
contribute to the script.

- Adding a new script for a device (Windows)
  1. Make a new directory in the root with a name like <device_name>_scripts
  2. In the new script directory, make a copy of the old setup scripts with the 
     same names as the old setup scripts:
    - Laptop_Setup_prep.bat
    - Laptop_Setup_update.bat
    - User_Setup_create.bat
    - User_Setup_configure.bat
  3. Copy the main menu script to the root (same directory) with a new name like 
     <device_name>_Setup.bat and make the following modifications:
    - Replace %script_path% with the path of the new scripts directory
    - Replace any mentions of the old device name with the new device name -- for
      example, if you're making a main menu script for an Optiplex 7090, replace
      all mentions of "Latitude 5320" with "Optiplex 7090".
  4. Make the necessary changes to port over the old setup scripts to the new device.

- \_\_common.bat is meant to be a function library for all scripts to use. You should
  only modify \_\_common.bat to fix bugs or to add a new common function. \_\_common.bat
  should never be run directly and never be invoked from a main menu script like
  Latitude_5320_Setup.bat.

- defaultapps.xml holds the default apps for the default user. This file is used
  by Laptop_Setup_prep.bat to set the default apps for the default user and thereby
  the default apps for all new users.

- 7-Zip-Installer-x64.txt is not used by the script, but is provided for the
  convenience of technicians using the script in case the target device does not
  have 7-Zip. All devices (Windows) should have 7-Zip included in the image so
  this is not necessary. The script requires 7-Zip to decrypt password hashes.
  The script also detects if 7-Zip is missing from the system and gives a warning
  to the technician if that is the case.

- hashes/ contains an encrypted .7z file containing the hashes that the scripts use
  to check if a password is correct or not. The hashes are decrypted and extracted
  to hashes/ using a password that the technician knows. The script will delete all
  hashes from the directory once the correct password is input, leaving only the
  .7z file.

- utils/ is a collection of miscellaneous utility scripts that are meant for developers
  of this script. None of the setup scripts call any scripts in utils/.

## Creating/Modifying Passwords

- To modify the hashes.7z password:
  1. Unzip the archive using the hashes password and then delete hashes.7z
  2. Select all of the hashes using Ctrl+LeftMouse
  3. Right click on your selection, press 7-Zip in the context (right-click) menu
     and "Add to archive...",
  4. At the top of the 7-Zip window, rename the archive to "hashes.7z"
  5. In the "Encryption" section in the bottom right, enter the new password in
     the password fields, make sure that the encryption method is AES-256, check 
     the "Encrypt file names" box, and press OK

- To create a new hash for a password:
  1. Create a file in a directory named "password.txt"
  2. In the file, type the password, type a space after the last character of the
     password, and then type a newline (Enter). Make sure to save the file
  3. Open cmd and cd to the directory with password.txt
  4. Type ```certutil -hashfile password.txt SHA512```. The command will output
     the hash in the cmd window. It should be a long string of alphanumeric characters.
  5. Create a new file with the name <password_name>.hash. The file name should
     describe what the password is used for -- for example, user.hash for the
     default password for new users.
  6. Paste the hash directly into the <password_name>.hash file. There should
     be no whitespaces in the file.
  7. Re-archive and re-encrypt the hashes.7z password by following the instructions
     "To modify the hashes.7z password" above, but you may use the same encryption
     password.

## Creating a New Default Apps .xml File

- To create a new default apps .xml file:
  1. Login as any user and set the default apps to the default apps that you would
     like for all users.
  2. Open a terminal and run the command below -- this command will create an .xml
     file with the filetype and program associations currently set in the current 
     directory:
     ```Dism /Online /Export-DefaultAppAssociations:"%cd%\defaultapps.xml" >nul```
  3. Delete the old defaultapps.xml from lib\ and replace it with the new file.

# Credits

molofgarb