# Instructions for running code on Spartan 6 Microboard using ISE 14.7:

	1. In Planahead
		a. Start new project
			i. Choose part "xc6slx9csg324-2"
		b. Add all sources
			i. "Design Sources" choice for all files in hdl/ directory
			ii. "Constraints" choice for all files in constr/ directory
			iii. "Existing IP" choice for microblaze core in ip/ directory
		c. Run synthesis
		d. Modify implementation settings
			i. Under "Translate (ngdbuild)" -> "More Options" add line
				1) -bm "C:/path/to/ip/folder/microblaze_mcs_v1_4_0.bmm"
				2) You'll be able to see this file after running synthesis
				3) For instance, on my PC this line is:
				4) -bm "C:/GitHub_Local/SuperAudioBoard/S6MicroBoard_PoC/ip/microblaze_mcs_v1_4_0.bmm"
		e. Run Implementation and generate a bitstream
		f. Don’t bother programming the board with the bitstream just yet, however.
	2. In SDK
		a. Choose a new workspace (or use an existing one if you wish)
		b. Select file -> new -> Application Project
			i. Under "Hardware Platform" select Create New
				1) This will open up a new dialog box for creating a new hardware platform
				2) Give the hw platform a name, and under "Target Hardware Specification" navigate to your "ip" directory and select the "microblaze_mcs_v1_4_0_sdk.xml" file.
					a) This should be the same directory as in the implementation settings
					b) Eg, on my PC, this is: "C:\GitHub_Local\SuperAudioBoard\S6MicroBoard_PoC\ip\microblaze_mcs_v1_4_0_sdk.xml"
				3) After selecting the XML file, the path to the BMM file should automatically be loaded.
				4) Click finish to complete the hardware platform generation
			ii. After finishing the HW platform generation, you should be back at the new application project dialog box.
				1) Verify that the "Hardware Platform" option is pointing to the newly created hw platform
			iii. Under "Target Software", leave the OS platform as standalone, the language as C, and set it to create a new board support package (BSP)
			iv. Click next, and make sure that the "Hello World" template is selected.
			v. Hit finish to create the application project
		c. Add the source files to the project
			i. Right click on the application project in the "Project Explorer" pane, and select "Import"
			ii. Under "General", select "File System", and click "Next"
			iii. In the "From directory" line, navigate to the "sw" directory
				1) On my PC, this is, "C:\GitHub_Local\SuperAudioBoard\S6MicroBoard_PoC\sw"
			iv. Click "Select All" to select all the files in this directory
			v. Click "Advanced" to show more options, and select "Create links in workspace" and all sub-options
				1) Both "Create virtual folders" and "Create link locations relative to …" should be checked
				2) Without the "Create links in workspace" option, all the selected files will be copied into whatever directory you chose as a workspace
			vi. Click Finished to import the files
		d. Add header file paths to project properties
			i. Right click on the application project in the "Project Explorer" pane and select "Properties"
			ii. Go to "C/C++ General" -> "Paths and Symbols" and select the "Includes" tab
			iii. Click "Add" and "Workspace" and navigate to the "src" subdirectory of your application project, and hit "OK"
			iv. Add another, but this time select "File System", and navigate to the "S6MicroBoard_PoC\sw\Drivers" directory and hit "OK"
		e. The project should now build successfully
			i. Select "Build All" under the "Project" menu to verify
		f. Now we can actually attempt to run the project
			i. First, connect the s6 uBoard up with both USB cables (one is for programming, the other has the UART for the serial monitor)
			ii. Under the "Xilinx Tools" menu, select "Program FPGA"
				1) The correct bitstream file will be in the Planahead project directory under the "proj_name.runs\impl_1\" directory.  Check planahead bitstream generation options if you can't find it
				2) The correct BMM file is "microblaze_mcs_v1_4_0_bd.bmm" and will be in the "ip" directory with all the other "microblaze_mcs_v1_4_0*" files
				3) Under "Software Configuration" use the default "bootloop" option.
				4) Select "Program"
				5) If it complains about being unable to connect to the programming cable, go to "Configure JTAG Settings" in the "Xilinx Tools" menu, and try selecting "Digilent USB Cable" as the JTAG Cable Type
			iii. Add a run configuration
				1) Select "Run Configurations" under the "Run" menu
				2) Select "Xilinx C/C++ application (GDB)" and create a new launch configuration (left most icon in bar above different application types)
				3) Select the "STDIO Connection" tab, check the "Connect STDIO to Console" select box, and change the baud rate to 115200
					a) You shouldn't need to change the COM port unless you have trouble getting any text in the Console window
				4) You should be able to leave the rest of the run configuration parameters as default.
				5) Click "Run" to run the program
					a) It will initialize the SuperAudioBoard, read back the register configuration, wait for the digital HPF to stabilize, and then ask which channel (L/R) to output and read from (it assumes that the outputs are looped back to the inputs.)
					b) Once a channel is selected, it will output a sine wave until the input buffer is full, then print out the recorded samples.

