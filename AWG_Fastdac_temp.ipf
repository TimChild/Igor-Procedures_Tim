

function fdAWG_add_wave(instrID, wave_num, add_wave)
	// Adds to the AWGs stored in the fastdac
	variable instrID
	variable wave_num  	// Which AWG to add to (currently allowed 0 or 1)
	wave add_wave		// add_wave should be 2D with add_wave[0] = mV setpoint for each step in wave
					   		// 									 add_wave[1] = how many samples to stay at each setpoint

	// assert add_wave is 2D and has no nans/blanks
	// assert wave_num = 0,1

	// get fd_address from instrID

	// convert to string in form "ADD_WAVE,<wave_num>,<sp0>,<#sp0>,...,<spn>,<#spn>"
	// check len < 128/256/512 characters  (size of buffer input to fd)
		// if not then split into necessary chunks

	// send command(s)

	// check response(s) ("WAVE,<wave_num>,<len_setpoints>")

	// add to wave fdAWG<wave_num> (2D of setpoints and sample times)

end


function fdAWG_clear_wave(instrID, wave_num)
	// Clears AWG# from the fastdac and the corresponding global wave in IGOR
	variable instrID
	variable wave_num // Which AWG to clear (currently allowed 0 or 1)

	// assert wave_num = 0,1

	// get fd_address...

	string cmd
	sprintf cmd, "CLR_WAVE,%d", wave_num
	//send command

	//check response == "WAVE,<wave_num>,0"

end


function fdAWG_record_values(ScanValues, rowNum, [RCCutoff, numAverage, notch, direction])

   // Almost exactly the same as fdacRecordValues with:
   //    Improved usage of structures
   //    Ability to use FDAC Arbitrary Wave Generator
   // Note: May be worth using this function to replace fdacRecordValues at somepoint


   // compare to earlier call of InitializeWaves
   fdRV_check_init()

end
