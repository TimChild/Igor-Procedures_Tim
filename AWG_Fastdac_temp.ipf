

function fdAWG_add_wave(instrID, wave_num, add_wave)
	// Adds to the AWGs stored in the fastdac
	variable instrID
	variable wave_num  	// Which AWG to add to (currently allowed 0 or 1)
	wave add_wave		// add_wave should be 2D with add_wave[0] = mV setpoint for each step in wave
					   		// 									 add_wave[1] = how many samples to stay at each setpoint



                        // ADD_WAVE,<wave number (for now just 0 or 1)>,<Setpoint 0 in mV>,<Number of samples at setpoint 0>,….<Setpoint n in mV>,<Number of samples at Setpoint n>
                        //
                        // Response:
                        //
                        // WAVE,<wavenumber>,<total number of setpoints accumulated in waveform>
                        //
                        // Example:
                        //
                        // ADD_WAVE,0,300.1,50,-300.1,200
                        //
                        // Response:
                        //
                        // WAVE,0,2


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

   // CLR_WAVE,<wave number>
   //
   // Response:
   //
   // WAVE,<wave number>,0
   //
   // Example:
   //
   // CLR_WAVE,1
   //
   // Response:
   //
   // WAVE,1,0


	// assert wave_num = 0,1

	// get fd_address...

	string cmd
	sprintf cmd, "CLR_WAVE,%d", wave_num
	//send command

	//check response == "WAVE,<wave_num>,0"

end


function fdAWG_record_values(ScanValues, AWG_list, FilterOpts, rowNum)
   struct sc_scanValues &scanValues
   struct fdAWG_list &AWG_list
   struct fdRV_Filter_options &FilterOpts
   variable rowNum
   // Almost exactly the same as fdacRecordValues with:
   //    Improved usage of structures
   //    Ability to use FDAC Arbitrary Wave Generator
   // Note: May be worth using this function to replace fdacRecordValues at somepoint
   // Note: Only works for 1 FastDAC! Not sure what implementation will look like for multiple yet


   struct fdRV_Struct S
   // Set up FastDac Record Values Struct.
   // Note: FilterOpts get stored in S.pl (pl= ProcessList)
   // Note: samplingFreq, measureFreq, numADCs also setup here.
   // Note: This is also where start, fin variables in ScanValues are converted to strings for FastDAC
   fdAWG_set_struct_base_vars(S, ScanValues, FilterOpts, rowNum)

   // Check InitWaves was run with fastdac=1
   fdRV_check_init()

   // Check within limits and ramprates
   fdRV_check_rr_lims(S)

   // Ramp to start of scan ignoring lims because already checked
   fdRV_ramp_start(S.sv, S.fdList, ignore_lims = 1)
   sc_sleep(S.sv.delayx) // Settle time for 2D sweeps

   // Start the AWG_RAMP
   fdAWG_start_AWG_RAMP(S, AWG_list)

   variable totalByteReturn = AWG_list.numCycles*AWG_list.numSteps*AWG_list.waveLen
   // TODO: Either check that totalByteReturn is a multiple of numADCs, or that waveLen is a multiple of ADCs to reduce aliasing
   variable looptime = 0
   // TODO: Is is OK to be storing datapoints with increasing x even though steps will be only every AWG.waveLen/numADCs
   looptime = fdRV_record_buffer(S, totalByteReturn)

   // update window
	string endstr
	endstr = readInstr(S.sv.instrID)
	endstr = sc_stripTermination(endstr,"\r\n")
	if(fdacCheckResponse(endstr,"AWG_RAMP...",isString=1,expectedResponse="RAMP_FINISHED"))
		fdRV_update_window(S.sv.instrID, S.fdList, S.numADCs)
	endif

   /////////////////////////
	//// Post processing ////
	/////////////////////////

	fdRV_Process_data(S)

		// check abort/pause status
	fdRV_check_sweepstate(S.sv.instrID)
	return looptime

end

function fdAWG_set_struct_base_vars(S, ScanVals, FilterOpts, rowNum)
   struct fdRV_Struct &S
   struct sc_scanValues &scanVals
   struct fdRV_Filter_options &FilterOpts
   variable rowNum
   S.sv = ScanVals
   S.rowNum = rowNum

   string starts = "", fins = ""
   fd_format_setpoints(S.sv.startx, S.sv.finx, S.sv.channelsx, starts, fins)  // Gets starts/fins in FD string format
   fdRV_set_scanList(s.fdList, rampCh, starts, fins)  // Sets fdList with CHs, starts, fins

   S.pl.RCCutoff = FilterOpts.RCcutoff
   S.pl.numAverage = FilterOpts.numAverage
   S.pl.notch_list = FilterOpts.notch_list

   S.pl.coefList = ""

   fdRV_set_measureFreq(S) // Sets S.samplingFreq/measureFreq/numADCs
end


function fdAWG_start_AWG_RAMP(S, AWG_list)
   struct fdRV_Struct &S
   struct fdAWG_list &AWG_list

   // AWG_RAMP,<number of waveforms>,<dac channel(s) to output waveform 0>,<dac channel(s) to output waveform n>,<dac channel(s) to ramp>,<adc channel(s)>,<initial dac voltage 1>,<…>,<initial dac voltage n>,<final dac voltage 1>,<…>,<final dac voltage n>,<# of waveform repetitions at each ramp step>,<# of ramp steps>
   //
   // Example:
   //
   // AWG_RAMP,2,012,345,67,0,-1000,1000,-2000,2000,50,50
   //
   // Response:
   //
   // <(2500 * waveform length) samples from ADC0>RAMP_FINISHED


   string cmd = "", dacs="", adcs=""
   dacs = replacestring(",",S.sl.daclist,"")
	adcs = replacestring(",",S.sl.adclist,"")
   // OPERATION, #N AWs, AW_dacs, DAC CHANNELS, ADC CHANNELS, INITIAL VOLTAGES, FINAL VOLTAGES, # OF Wave cycles per step, # ramp steps
   // Note: AW_dacs is formatted (dacs_for_wave0, dacs_for_wave1, .... e.g. '01,23' for Dacs 0,1 to output wave0, Dacs 2,3 to output wave1)
	sprintf cmd, "AWG_RAMP,%d, %s, %s,%s,%s,%s, %d, %d\r", AWG_list.numWaves, AWG_list.dacs, dacs, adcs, S.sl.startVal, S.sl.finVal, AWG_list.numCycles, AWG_list.numSteps
	writeInstr(S.sv.instrID,cmd)

end



structure fdAWG_list
   // Note: AW_dacs is formatted (dacs_for_wave0, dacs_for_wave1, .... e.g. '01,23' for Dacs 0,1 to output wave0, Dacs 2,3 to output wave1)
   string dacs
   variable numWaves   // # different AWGs (currently 1 or 2 only)
   variable waveLen    // in samples (i.e. sum of samples at each setpoint for a single wave cycle)
   variable numCycles  // # wave cycles per DAC step for a full 1D scan
   variable numSteps   // # DAC steps for a full 1D scan
endstructure


structure fdRV_Filter_options
   variable RCCutoff
   variable numAverage
   string notch_list
endstructure
