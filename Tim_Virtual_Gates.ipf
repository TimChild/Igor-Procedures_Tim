// 31/3/2020 -- This file is out of date, was for measurement taken a year ago.
// Probably will be useful if ever wanting to add Virtual gates to measurement
// again.



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////// VIRTUAL GATES ////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function AAVirtualGates()
end


function define_virtual_gate_origin()
	// this function defines the virtual gate origin in a wave
	make /o virtual_gate_origin = {0,1150,0,-25,0,-238,-630,-510,-2190,-630,-630,-275,-4091,-390,-400,-995}
end

function define_virtual_gate_couplings()
	// this function defines the virtual gate couplings
	make /o virtual_gate_couplings = {{0.981,0.681,0,0},{0.133,0.936,0,0},{3.938,7.419,1,0},{3.69,1.32,0,1}}
	matrixop /o inv_gate_couplings = inv(virtual_gate_couplings)
end

//ScanVirtualGates2D(bd6, -8, 10, "VP1", 181, 0.3, -5, 5, "VP1", 3, 1.0, vp2=4)

function reset_gates_to_origin(instrID)
	// resets all the gates to the point from which the virtual gates are defined
	// only changes DAC5-14
	// channels 0-4 are biases and unused channels
	// channel 15 controls the heater QPC and should have a minimal coupling to the dots
	variable instrID
	define_virtual_gate_origin()
	wave vgo = virtual_gate_origin

	variable i=0
	for(i=5;i<15;i+=1)
		RampOutputBD(instrID, i, vgo[i])
	endfor
end


function RampVirtualGates(instrID, GateKeyString)
	// example GateKeyString = "VP1:0;VP2:0;VG1:0;VG2:0"
	// vp_small and vp_big are deltas
	// both virtual gates are equal to zero at the virtual gate origin
	variable instrID
	String GateKeyString

	variable vp_small, vp_big, vg_coup, vg_res

	vp_small = NumberByKey("VP1", GateKeyString)
	vp_big = NumberByKey("VP2", GateKeyString)
	vg_coup = NumberByKey("VG1", GateKeyString)
	vg_res = NumberByKey("VG2", GateKeyString)

	if(numtype(vp_small)!=0 || numtype(vp_big)!=0 || numtype(vg_coup)!=0 || numtype(vg_res)!=0)
		print GateKeyString
		abort("Incorrect format for GateKeyString. Should be e.g. 'VP1:0;VP2:0;VG1:0;VG2:0'")
	endif

	wave vgo = virtual_gate_origin
	wave igc = inv_gate_couplings
	make /o vg_deltas = {vp_small, vp_big, vg_coup, vg_res}
	MatrixOP /o gate_deltas = igc x vg_deltas


//	print vgo[12]+gate_deltas[0], vgo[8]+gate_deltas[1], vgo[11]+gate_deltas[2], vgo[13]+gate_deltas[3]

	RampOutputBD(instrID, 12, vgo[12]+gate_deltas[0], ramprate=1000)
//	sc_sleep(0.01)
	RampOutputBD(instrID, 8, vgo[8]+gate_deltas[1], ramprate=1000)
//	sc_sleep(0.01)
	RampOutputBD(instrID, 11, vgo[11]+gate_deltas[2], ramprate=1000)
//	sc_sleep(0.01)
	RampOutputBD(instrID, 13, vgo[13]+gate_deltas[3], ramprate=1000)
//	sc_sleep(0.01)

end

function checkgatevalid(gate)
	string gate
	string gatelist="VP1;VP2;VG1;VG2"
	int i=0

	for (i=0; i<4; i+=1)
		if (cmpstr(gate, stringfromlist(i, gatelist))==0)
			return 1
		endif
	endfor
	abort("One of the Gate choices was invalid")
end

function ScanVirtualGates2D(instrID, startx, finx, xgate, numptsx, delayx, starty, finy, ygate, numptsy, delayy, [vp1, vp2, vg1, vg2,comments]) //Units: mV
	// Coupling between dots in x
	// small dot transitions in y

	variable instrID, startx, finx, numptsx, delayx, starty, finy, numptsy, delayy, vp1, vp2, vg1, vg2
	string xgate, ygate, comments
	variable i=0, j=0, setpointx, setpointy
	string x_label="", y_label="", GKS="" //GateKeyString

	checkgatevalid(xgate)
	checkgatevalid(ygate)


	if (cmpstr(xgate, ygate) == 0)
		abort("x and y gates were equal")
	endif


	if(paramisdefault(comments))
		comments=""
	endif

  	if(ParamIsDefault(vp1))
		vp1=0
	elseif (cmpstr(xgate, "VP1")==0 || cmpstr(ygate, "VP1")==0)
		abort("optional gate same as x or y gate")
	endif
  	if(ParamIsDefault(vp2))
		vp2=0
	elseif (cmpstr(xgate, "VP2")==0 || cmpstr(ygate, "VP2")==0)
		abort("optional gate same as x or y gate")
	endif
	if(ParamIsDefault(vg1))
		vg1=0
	elseif (cmpstr(xgate, "VG1")==0 || cmpstr(ygate, "VG1")==0)
		abort("optional gate same as x or y gate")
	endif
	if(ParamIsDefault(vg2))
		vg2=0
	elseif (cmpstr(xgate, "VG2")==0 || cmpstr(ygate, "VG2")==0)
		abort("optional gate same as x or y gate")
	endif

	GKS = replaceNumberByKey("VP1", GKS, vp1)
	GKS = replaceNumberByKey("VP2", GKS, vp2)
	GKS = replaceNumberByKey("VG1", GKS, vg1)
	GKS = replaceNumberByKey("VG2", GKS, vg2)

	setpointx = startx
	setpointy = starty
	GKS = replaceNumberByKey(xgate, GKS, setpointx)
	GKS = replacenumberByKey(ygate, GKS, setpointy)


	sprintf x_label, xgate
	sprintf y_label, ygate

	// set starting values
	define_virtual_gate_origin()
	define_virtual_gate_couplings()

	RampVirtualGates(instrID, GKS)
	sc_sleep(4.0)

	// initialize waves
	InitializeWaves(startx, finx, numptsx, starty=starty, finy=finy, numptsy=numptsy, x_label=x_label, y_label=y_label)

	// main loop
	do
		setpointx = startx
		setpointy = starty + (i*(finy-starty)/(numptsy-1))
		GKS = replaceNumberByKey(xgate, GKS, setpointx)
		GKS = replacenumberByKey(ygate, GKS, setpointy)
		RampVirtualGates(instrID, GKS)
		sc_sleep(delayy)
		j=0
		do
		  setpointx = startx + (j*(finx-startx)/(numptsx-1))
		  GKS = replacenumberByKey(xgate, GKS, setpointx)
		  RampVirtualGates(instrID, GKS)
		  sc_sleep(delayx)
		  RecordValues(i, j)
		  j+=1
		while (j<numptsx)
		i+=1
	while (i<numptsy)
	SaveWaves(msg=comments)
end

function ScanVirtualGate(instrID, startx, finx, xgate, numptsx, delayx, [vp1, vp2, vg1, vg2,comments]) //Units: mV

	variable instrID, startx, finx, numptsx, delayx, vp1, vp2, vg1, vg2
	string xgate, comments
	variable j=0, setpointx
	string x_label="", GKS="" //GateKeyString

	checkgatevalid(xgate)


	if(paramisdefault(comments))
		comments=""
	endif

  	if(ParamIsDefault(vp1))
		vp1=0
	elseif (cmpstr(xgate, "VP1")==0)
		abort("optional gate same as x gate")
	endif
  	if(ParamIsDefault(vp2))
		vp2=0
	elseif (cmpstr(xgate, "VP2")==0)
		abort("optional gate same as x gate")
	endif
	if(ParamIsDefault(vg1))
		vg1=0
	elseif (cmpstr(xgate, "VG1")==0)
		abort("optional gate same as x gate")
	endif
	if(ParamIsDefault(vg2))
		vg2=0
	elseif (cmpstr(xgate, "VG2")==0)
		abort("optional gate same as x gate")
	endif

	GKS = replaceNumberByKey("VP1", GKS, vp1)
	GKS = replaceNumberByKey("VP2", GKS, vp2)
	GKS = replaceNumberByKey("VG1", GKS, vg1)
	GKS = replaceNumberByKey("VG2", GKS, vg2)

	setpointx = startx
	GKS = replaceNumberByKey(xgate, GKS, setpointx)


	sprintf x_label, xgate

	// set starting values
	define_virtual_gate_origin()
	define_virtual_gate_couplings()

	RampVirtualGates(instrID, GKS)
	sc_sleep(4.0)

	// initialize waves
	InitializeWaves(startx, finx, numptsx, x_label=x_label)

	// main loop

	do
	  setpointx = startx + (j*(finx-startx)/(numptsx-1))
	  GKS = replacenumberByKey(xgate, GKS, setpointx)
	  RampVirtualGates(instrID, GKS)
	  sc_sleep(delayx)
	  RecordValues(j,0)
	  j+=1
	while (j<numptsx)
	SaveWaves(msg=comments)
end

function ScanVirtualGateRepeat(instrID, startx, finx, xgate, numptsx, delayx, numptsy, delayy, [vp1, vp2, vg1, vg2,comments]) //Units: mV
	// Coupling between dots in x
	// small dot transitions in y

	variable instrID, startx, finx, numptsx, delayx, numptsy, delayy, vp1, vp2, vg1, vg2
	string xgate, comments
	variable i=0, j=0, setpointx, starty=1, finy=numptsy
	string x_label="", y_label="Repeats", GKS="" //GateKeyString

	checkgatevalid(xgate)

	if(paramisdefault(comments))
		comments=""
	endif

  	if(ParamIsDefault(vp1))
		vp1=0
	elseif (cmpstr(xgate, "VP1")==0)
		abort("optional gate same as x gate")
	endif
  	if(ParamIsDefault(vp2))
		vp2=0
	elseif (cmpstr(xgate, "VP2")==0)
		abort("optional gate same as x gate")
	endif
	if(ParamIsDefault(vg1))
		vg1=0
	elseif (cmpstr(xgate, "VG1")==0)
		abort("optional gate same as x gate")
	endif
	if(ParamIsDefault(vg2))
		vg2=0
	elseif (cmpstr(xgate, "VG2")==0)
		abort("optional gate same as x gate")
	endif

	GKS = replaceNumberByKey("VP1", GKS, vp1)
	GKS = replaceNumberByKey("VP2", GKS, vp2)
	GKS = replaceNumberByKey("VG1", GKS, vg1)
	GKS = replaceNumberByKey("VG2", GKS, vg2)

	setpointx = startx

	GKS = replaceNumberByKey(xgate, GKS, setpointx)



	sprintf x_label, xgate

	// set starting values
	define_virtual_gate_origin()
	define_virtual_gate_couplings()

	RampVirtualGates(instrID, GKS)
	sc_sleep(4.0)

	// initialize waves
	InitializeWaves(startx, finx, numptsx, starty=starty, finy=finy, numptsy=numptsy, x_label=x_label, y_label=y_label)

	// main loop
	do
		setpointx = startx
		GKS = replaceNumberByKey(xgate, GKS, setpointx)
		RampVirtualGates(instrID, GKS)
		sc_sleep(delayy)
		j=0
		do
		  setpointx = startx + (j*(finx-startx)/(numptsx-1))
		  GKS = replacenumberByKey(xgate, GKS, setpointx)
		  RampVirtualGates(instrID, GKS)
		  sc_sleep(delayx)
		  RecordValues(i, j)
		  j+=1
		while (j<numptsx)
		i+=1
	while (i<numptsy)
	SaveWaves(msg=comments)
end


function cutFunc(xval, yval)
	// this function is a template needed for the scan function defined below
	variable xval,yval
end

function ScanVirtualGates2Dcut(instrID, startx, finx, xgate, numptsx, delayx, starty, finy, ygate, numptsy, delayy, func, [vp1, vp2, vg1, vg2,comments]) //Units: mV
	// Coupling between dots in x
	// small dot transitions in y

	variable instrID, startx, finx, numptsx, delayx, starty, finy, numptsy, delayy, vp1, vp2, vg1, vg2
	string xgate, ygate, func, comments
	variable i=0, j=0, setpointx, setpointy
	string x_label="", y_label="", GKS="" //GateKeyString

	FUNCREF cutFunc fcheck=$func

	checkgatevalid(xgate)
	checkgatevalid(ygate)


	if (cmpstr(xgate, ygate) == 0)
		abort("x and y gates were equal")
	endif


	if(paramisdefault(comments))
		comments=""
	endif

  	if(ParamIsDefault(vp1))
		vp1=0
	elseif (cmpstr(xgate, "VP1")!=0 || cmpstr(ygate, "VP1")!=0)
		abort("optional gate same as x or y gate")
	endif
  	if(ParamIsDefault(vp2))
		vp2=0
	elseif (cmpstr(xgate, "VP2")!=0 || cmpstr(ygate, "VP2")!=0)
		abort("optional gate same as x or y gate")
	endif
	if(ParamIsDefault(vg1))
		vg1=0
	elseif (cmpstr(xgate, "VG1")!=0 || cmpstr(ygate, "VG1")!=0)
		abort("optional gate same as x or y gate")
	endif
	if(ParamIsDefault(vg2))
		vg2=0
	elseif (cmpstr(xgate, "VG2")!=0 || cmpstr(ygate, "VG2")!=0)
		abort("optional gate same as x or y gate")
	endif

	GKS = replaceNumberByKey("VP1", GKS, vp1)
	GKS = replaceNumberByKey("VP2", GKS, vp2)
	GKS = replaceNumberByKey("VG1", GKS, vg1)
	GKS = replaceNumberByKey("VG2", GKS, vg2)

	setpointx = startx
	setpointy = starty
	GKS = replaceNumberByKey(xgate, GKS, setpointx)
	GKS = replacenumberByKey(ygate, GKS, setpointy)


	sprintf x_label, xgate
	sprintf y_label, ygate

	// set starting values
	define_virtual_gate_origin()
	define_virtual_gate_couplings()

	RampVirtualGates(instrID, GKS)
	sc_sleep(4.0)

	// initialize waves
	InitializeWaves(startx, finx, numptsx, starty=starty, finy=finy, numptsy=numptsy, x_label=x_label, y_label=y_label)

	// main loop
	do
		j=0
		setpointx = startx
		setpointy = starty + (i*(finy-starty)/(numptsy-1))

		do
			setpointx = startx + (j*(finx-startx)/(numptsx-1))
			if( fcheck(setpointx, setpointy) == 0 && j<numptsx)
				RecordValues(i, j, fillnan=1)
				j+=1
			else
				break
			endif
		while( 1 )

		if (j == numptsx)
			i+=1
			continue
		endif

		GKS = replacenumberByKey(ygate, GKS, setpointy)
	   GKS = replacenumberByKey(xgate, GKS, setpointx)
	   RampVirtualGates(instrID, GKS)
		sc_sleep(delayy)

		do
		  setpointx = startx + (j*(finx-startx)/(numptsx-1))
		  if( fcheck(setpointx, setpointy) == 0 )
		     RecordValues(i, j, fillnan=1)
		  else
		     GKS = replacenumberByKey(xgate, GKS, setpointx)
		     RampVirtualGates(instrID, GKS)
		     sc_sleep(delayx)
		     RecordValues(i, j)
		  endif
		  j+=1
		while (j<numptsx)

		i+=1
	while (i<numptsy)
	SaveWaves(msg=comments)
end
