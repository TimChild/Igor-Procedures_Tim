//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////// My Analysis ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////// Display/Analysis Functions ////////////////
function plot_waterfall(w, x_label, y_label, [y_spacing])
	wave w
	string x_label, y_label
	variable y_spacing
	
	display
	setWindow kwTopWin, graphicsTech=0		
	duplicate/o w tempwave
	variable i
	for (i=0; i<dimsize(w, 1); i++)
		tempwave[][i] = tempwave[p][i]+y_spacing*i
		AppendToGraph tempwave[][i]
	endfor
	setupGraph1D(WinName(0,1), x_label, y_label=y_label)
end

function DisplayDiff(w, [x_label, y_label, filenum])
	wave w
	string x_label, y_label
	variable filenum
	
	x_label = selectstring(paramisdefault(x_label), x_label, "No x_label")
	y_label = selectstring(paramisdefault(y_label), y_label, "No y_label")
	
	string window_name = ""
	sprintf window_name, "%s__differentiated", nameofwave(w)
	string wn = ""
	sprintf wn, "%s__diffx", nameofwave(w)	
	
	wave tempwave = Diffwave(w)

	dowindow/k $window_name
	display/N=$window_name
	appendimage tempwave
	ModifyImage tempwave ctab= {*,*,VioletOrangeYellow,0}
	TextBox/W=$window_name/C/N=textid/A=LT/X=1.00/Y=1.00/E=2 window_name	
	Label left, y_label
	Label bottom, x_label
	if (filenum > 0)
		string text
		sprintf text "Dat%d", filenum
		TextBox/W=$window_name/C/N=datnum/A=LT text
	endif
end


function/wave DiffWave(w)
	wave w
	
	duplicate/o w, tempwave
	smooth/DIM=0 ceil(dimsize(w,0)/10), tempwave
	differentiate/DIM=0 tempwave	
	return tempwave
end

function DisplayMultiple(datnums, name_of_wave, [diff, x_label, y_label])
// Plots data from each dat on same axes... Will differentiate first if diff = 1
	wave datnums
	string name_of_wave, x_label, y_label
	variable diff

	svar sc_x_label, sc_y_label
	x_label = selectstring(paramisdefault(x_label), x_label, sc_x_label)
	y_label = selectstring(paramisdefault(y_label), y_label, sc_y_label)
	
	string window_name
	sprintf window_name, "Dats%dto%d", datnums[0], datnums[numpnts(datnums)-1]
	dowindow/k $window_name
	display/N=$window_name
	TextBox/W=$window_name/C/N=textid/A=LT/X=1.00/Y=1.00/E=2 window_name	
	
	
	variable i = 0, datnum
	string wn
	string tempwn
	for(i=0; i < numpnts(datnums); i++)
		datnum = datnums[i]
		sprintf wn, "dat%d%s", datnum, name_of_wave
		sprintf tempwn, "tempwave_%s", wn
		duplicate/o $wn, $tempwn
		wave tempwave = $tempwn
		if (diff == 1)
			wave tempwave2 = diffwave($tempwn)
			tempwave = tempwave2
		endif
		appendimage/W=$window_name tempwave
		ModifyImage/W=$window_name $tempwn ctab= {*,*,VioletOrangeYellow,0}
	endfor
	Label left, y_label
	Label bottom, x_label

end


function DisplayWave(w, [x_label, y_label])
	wave w
	string x_label, y_label
	
	svar sc_x_label, sc_y_label
	x_label = selectstring(paramisdefault(x_label), x_label, sc_x_label)
	y_label = selectstring(paramisdefault(y_label), y_label, sc_y_label)
	
	string name, wn = nameofwave(w)
	sprintf name "%s_", wn
	
	svar sc_colormap
	dowindow/k $name
	display/N=$name
	setwindow kwTopWin, graphicsTech=0
	appendimage $wn
	modifyimage $wn ctab={*, *, $sc_ColorMap, 0}
	colorscale /c/n=$sc_ColorMap /e/a=rc
	Label left, y_label
	Label bottom, x_label
	TextBox/W=$name/C/N=textid/A=LT/X=1.00/Y=1.00/E=2 name
	
end



function Display3VarScans(wavenamestr, [v1, v2, v3, uselabels, usecolorbar, diffchargesense, switchrowscols, scanset, showentropy])
// This function is for displaying plots from 3D/4D/5D scans (i.e. series of 2D scans where other parameters are changed between each scan)
//v1, v2, v3 are looking for indexes e.g. "3" or range of indexs e.g. "2, 5" of the other parameters to display
//v1gmax, v2gmax, v3gmax below are the number of different values used for each parameter. These need to be hard coded
//datstart below needs to be hardcoded as the first dat of the sweep array
//uselabels also requires some hard coded variables to be set up below
//Usecolorbar = 0 does not show colorscale, = 1 shows it
//diffchargesense differentiates charge sensor data in the y direction (may want to change direction of differentiation later)

// TODO:Currently works for 5D, will need some adjusting to work for 3D, 4D.
	string wavenamestr //Takes comma separated wave names e.g. "g1x2d, v5dc"
	string v1, v2, v3 // Charge Sensor Right, Chare Sensor total, Small Dot Plunger
	variable uselabels, usecolorbar, diffchargesense, switchrowscols, scanset, showentropy //set to 1 to use //TODO: make rows cols be right all the time


	variable datstart, v1start, v2start, v3start, v1step, v2step, v3step
	variable/g v1gmax, v2gmax, v3gmax

	if (paramisdefault(scanset))
		print "Using Default parameters"
		//	////////////////// SET THESE //////////////////////////////////////////////////
		//	datstart = 328
		//	v1gmax = 7; v2gmax = 5; v3gmax = 6 //Have to make global to use NumVarOrDefault...
		//	v1start = -200; v2start = -550; v3start = -200
		//	v1step = -50; v2step = -50; v3step = -100
		//	make/o/t varlabels = {"CSR", "CStotal", "SDP"}
		//	make/o/t axislabels = {"SDL", "SDR"} //y, x
		//	///////////////////////////////////////////////////////////////////////////////

		//	///////////////////////////////////////////////////////////////////////////////

	else
		switch (scanset)
			case 1:
				// Right side of NikV2 15th feb 2020
				datstart = 88
				v1gmax = 5; v2gmax = 5; v3gmax = 2 //Have to make global to use NumVarOrDefault...
				v1start = -100; v2start = -0; v3start = -300
				v1step = -100; v2step = -100; v3step = -500
				make/o/t varlabels = {"RCB", "RP", "RCSQ"}
				make/o/t axislabels = {"RCSS", "RCT"} //y, x
				break
			case 2:
				datstart = 139
				v1gmax = 8; v2gmax = 4; v3gmax = 1 //Have to make global to use NumVarOrDefault...
				v1start = 0; v2start = -100; v3start = 0
				v1step = -25; v2step = -50; v3step = 0
				make/o/t varlabels = {"LP", "LCSS", ""}
				make/o/t axislabels = {"LCT", "LCB"} //y, x
				break
		endswitch
	endif


	usecolorbar = paramisdefault(usecolorbar) ? 1 : usecolorbar
	diffchargesense = paramisdefault(diffchargesense) ? 1 : diffchargesense
	make/o/t varnames = {"v1g", "v2g", "v3g"}
	make/o/t varrangenames = {"v1range", "v2range", "v3range"}
	make/o/t varlistvals = {"v1vals", "v2vals", "v3vals"}

	variable check=0, i=0, j=0, k=0

	if (paramisdefault(v1))
		v1=""
		check+=1
	endif
	if (paramisdefault(v2))
		v2=""
		check+=1
	endif
	if (paramisdefault(v3))
		v3=""
		check+=1
	endif
	string/g v1g = v1, v2g = v2, v3g = v3 //Have to make global to use StrVarOrDefault because cant use $ inside function becuse Igor is stupid
	if (check == 3)
		abort "Select one or more values to see graphs"
	endif
	check = 0

	variable fixedvarval, n

	string v, str

	do
		v = StrVarOrDefault(varnames[i], "") // Makes v = one of the input string variables  equivalent to v = $varnames[i]
		if (itemsinlist(v, ",") == 1)
			fixedvarval = i
			check += 1
		endif
		i+=1
	while (i<3)
	if (check == 0)
		abort "Must specify value of one variable at least"
	endif


	i=0; j=0
	do
		str = varrangenames[i];	make/o/n=2 $str = NaN; wave vrname = $str    // Igor's stupid way of making a wave with a name from a text wave
		str = varlistvals[i]; make/o $str = NaN; wave vlname = $str

		v = StrVarOrDefault(varnames[i], "")
		vrname = str2num(StringFromList(p, v, ","))
		wavestats/q vrname
		n = numvarOrDefault(varnames[i]+"max", -1)-1 //-1 at end because counting starts at 0. Should never have to default to -1
		if (V_npnts == 0)
			vrname = {0, n} //effectively default to max range
		elseif (V_npnts == 1)
			vrname[1] = vrname[0] //Just same value twice so that calc vals works
		endif
		do  //fills val wave with all values wanted
			vlname[j] = vrname[0] + j
			j+=1
		while (j < vrname[1]-vrname[0]+1)
		redimension/n=(vrname[1]-vrname[0]+1) vlname
		if (vrname[1] > n)
			printf "Max range for %s is %d, automatically set to max\n", varlabels[i], n
			vrname[1] = n
		endif
		j=0
		i+=1
	while (i<numpnts(varnames))


	make/o datlist = NaN
	make/o varvals = NaN
	make/o varindexs = NaN
	variable c=0 //for counting what place in datlist
	i=0; j=0; k=0
	do  // Makes list of datnums to display
		do
			do
				str = varlistvals[0]; wave w0 = $str //v1vals = fast
				str = varlistvals[1]; wave w1 = $str //v2vals = medium
				str = varlistvals[2]; wave w2 = $str //v3vals = slow

				datlist[c] = datstart+w0[k]+w1[j]*v1gmax+w2[i]*v2gmax*v1gmax
				if (uselabels!=0)
					varindexs[c] = {{w0[k]}, {w1[j]}, {w2[i]}}
					varvals[c] = {{v1start+w0[k]*v1step}, {v2start+w1[j]*v2step}, {v3start+w2[i]*v3step}}
				endif
				c+=1
				k+=1
			while (k < numpnts(w0))
			k=0
			j+=1
		while (j < numpnts(w1))
		j=0
		i+=1
	while (i < numpnts(w2))
	redimension/n=(numpnts(w0)*numpnts(w1)*numpnts(w2), -1) datlist, varvals, varindexs //just removes NaNs at end of waves
	string rowcolvars = "012"
	rowcolvars = replacestring(num2str(fixedvarval), rowcolvars, "")
	str = varlistvals[str2num(rowcolvars[0])]; wave w0 = $str
	str = varlistvals[str2num(rowcolvars[1])]; wave w1 = $str
	//// TODO: make this unnecessary
	variable rows = numpnts(w0), cols = numpnts(w1)
	if (switchrowscols == 1)
		variable temp
		temp = rows
		rows = cols
		cols = temp
	endif
	//
	tilegraphs(datlist, wavenamestr, rows = rows, cols = cols, axislabels=axislabels, varlabels=varlabels, varvals=varvals, varindexs=varindexs, uselabels=uselabels, usecolorbar=usecolorbar, diffchargesense=diffchargesense, showentropy=showentropy)
end




function tilegraphs(dats, wavenamesstr, [rows, cols, axislabels, varlabels, varvals, varindexs, uselabels, usecolorbar, diffchargesense, showentropy]) // Need all of varlabels, varvals, varindexs to use them
	// Takes list of dats and tiles 4x4 by default or if specified
	// Designed to work with display3VarScans although it should work with other things. Might help to look at display3varscans to understand this though.
	wave dats
	string wavenamesstr //Can be one or multiple wavenames separated by "," e.g. "g1x2d, v5dc"
	variable rows, cols
	wave/t axislabels, varlabels
	wave varvals, varindexs
	variable uselabels, usecolorbar, diffchargesense, showentropy
	svar sc_colormap

	abort "Can this use the ScanController Graphs stuff now?"

	rows = paramisdefault(rows) ? 4 : rows
	cols = paramisdefault(cols) ? 4 : cols

	make/o/t/n=(itemsinlist(wavenamesstr, ",")) wavenames
	variable i=0, j=0
	make/o/t/n=(itemsinlist(wavenamesstr, ",")) wavenames
	do
		wavenames[i] = removeleadingwhitespace(stringfromlist(i, wavenamesstr, ","))
		i+=1
	while (i<(itemsinlist(wavenamesstr, ",")))
	string wn = "", activegraphs = "", wintext
	i=0;j=0
	do
		do
			sprintf wn, "dat%d%s", dats[i], wavenames[j]
			if (cmpstr(wn[-2,-1], "2d", 0))	// case insensitive
				if (diffchargesense!=0 && (stringmatch(wn, "*Ch0*") == 1 || stringmatch(wn, "*sense*")))
					duplicate/o $wn $wn+"diff"
					wn = wn+"diff"
					differentiate/dim=1 $wn
				endif
				display
				setwindow kwTopWin, enablehiresdraw=3
				appendimage $wn
				modifyimage $wn ctab={*, *, $sc_ColorMap, 0}//, margin(left)=40,margin(bottom)=25,gfSize=10, margin(right)=3,margin(top)=3
				//modifyimage $wn gfMult=75
				modifygraph gfMult=75, margin(left)=35,margin(bottom)=25, margin(right)=3,margin(top)=3
				if (usecolorbar != 0)
					colorscale /c/n=$sc_ColorMap /e/a=rc
				endif
				Label left, axislabels[0]
				Label bottom, axislabels[1]
				if (showentropy == 1)
					wave fitdata
					fitentropy(dats[i]);duplicate/o/free/rmd=[][3][0] fitdata, testwave
					TextBox/C/N=datnum/A=LT/X=1.00/Y=1.00/E=2 "Dat="+num2str(dats[i])+"\r"+num2str(mean(testwave))
				else
					TextBox/C/N=datnum/A=LT/X=1.00/Y=1.00/E=2 "Dat="+num2str(dats[i])
				endif
				//TextBox/C/N=vars/A=rb/X=0.00/Y=0.00/E=2 "v1=4, v2=5, v3=6"
				if (uselabels!=0)
					sprintf wintext, "v1=%d, v2=%d, v3=%d, %s=%.3GmV, %s=%.3GmV, %s=%.3GmV: %s", varindexs[i][0], varindexs[i][1], varindexs[i][2], varlabels[0], varvals[i][0], varlabels[1], varvals[i][1], varlabels[2], varvals[i][2], wn
					DoWindow/T kwTopWin, wintext
				endif
			else
				display $wn
				setwindow kwTopWin, enablehiresdraw=3
				if (showentropy == 1)
					wave fitdata
					fitentropy(dats[i]);duplicate/o/free/rmd=[][3][0] fitdata, testwave
					TextBox/C/N=datnum/A=LT/X=1.00/Y=1.00/E=2 "Dat="+num2str(dats[i])+"\r"+num2str(mean(testwave))
				else
					TextBox/C/N=datnum/A=LT/X=1.00/Y=1.00/E=2 "Dat="+num2str(dats[i])
				endif
			endif
			activegraphs+= winname(0,1)+";"
			j+=1
		while (j < numpnts(wavenames))
		j=0
		i+=1
	while (i< numpnts(dats))
	string cmd1, cmd2
	variable maxw=33*cols, maxh=33*rows
	maxw = maxw > 100 ? 100 : maxw
	maxh = maxh > 100 ? 100 : maxh
	sprintf cmd1, "TileWindows/O=1/A=(%d,%d)/r/w=(0,0,%d, %d) ", rows, cols*itemsinlist(wavenamesstr, ","), maxw, maxh
	cmd2 = ""
	string window_string
	for(i=0;i<itemsinlist(activegraphs);i=i+1)
		window_string = stringfromlist(i,activegraphs)
		cmd1+= window_string +","

		cmd2 = "DoWindow/F " + window_string
		execute(cmd2)
	endfor
	execute(cmd1)
end


function fitentropy(datnum)
	variable datnum
	string datname
//	datname = "dat"+num2str(datnum)+"FastscanCh1_2d"
	datname = "dat"+num2str(datnum)+"g1x2d"
	wave loaddat=$datname  // sets dat to be dat...g2x2d
	duplicate/o loaddat, dat
	variable Vmid, theta, const, dS, dT
	variable i=0, datnumber
	wave w_sigma //for collecting erros from FuncFit
	make /O /N=(dimsize(dat,0)) datrow
	SetScale/P x dimoffset(dat,0),dimdelta(dat,0),"", datrow

	//killwaves/z fitdata
	make/D /O /N=(dimsize(dat,1), 6, 3) fitdata  //last column is for storing other info like dat number, y scale


	//Make/D/N=5/O temp

	//W_coef[0] = {-3048,1.2,0,0.5,-0.00045}
	//W_coef[0] = {Vmid,theta,const,dS,dT}
	make/free/O tempwave =  {{-3048},{1.2},{0},{0.5},{-0.00045},{0}} //gets overwritten with data specific estimates before funcfit
	fitdata[][0,4][0] = tempwave[0][q]
	fitdata[0][5][0] = datnum


	i=0
	do
		datrow[] = dat[p][i]
		fitdata[i][5][2] = dimoffset(dat, 1)+i*dimdelta(dat, 1) // records y values in fitdata for use in plot entropy
		wavestats/Q datrow
		if (v_npnts < 50 && i < (dimsize(dat,1)-1)) //Send back to beginning if not enough points in datrow
			i+=1
			continue
		elseif (v_npnts < 50 && i >= (dimsize(dat,1)-1))
			break
		endif
		//W_coef[0] = {(v_MinLoc + (V_MaxLoc-V_minLoc)/2),v_maxloc-V_minloc,0,0.5,-0.00040}
		fitdata[i][0,4][0] = {{(v_MinLoc + (V_MaxLoc-V_minLoc)/2)},{-v_maxloc+V_minloc},{0},{0.5},{-0.50}}
		fitdata[i][0,4][2] = fitdata[i][q][0] //save initial guess in page3

//		FuncFit /Q Entropy1CK W_coef datrow /D
		FuncFit /Q Entropy1CK fitdata[i][0,4][0] datrow
		fitdata[i][0,4][1] = w_sigma[q] //Save errors on page2
		i+=1
	while (i<dimsize(dat, 1))
//	while (i<1)


end

function fitentropy1D(dat)

	wave dat

	variable Vmid, theta, const, dS, dT
	variable i=0

	make /O /N=(5) fitdata

	Make/D/N=5/O W_coef

	W_coef[0] = {-3048,1.2,0,0.5,-0.00045}
	//W_coef[0] = {Vmid,theta,const,dS,dT}

	wavestats /Q dat
	W_coef[0] = {(v_MinLoc + (V_MaxLoc-V_minLoc)/2),v_maxloc-V_minloc,0,0.5,-0.0080}

	display dat
	FuncFit /Q Entropy1CK W_coef dat /D

	fitdata[] = w_coef[p]



end



Function Entropy1CK(w,Vp) : FitFunc
	Wave w
	Variable Vp

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(Vp) = -(dT)*((Vp-Vmid)/(2*theta)-0.5*dS)*(cosh((Vp-Vmid)/(2*theta)))^(-2)+const
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ Vp
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = Vmid
	//CurveFitDialog/ w[1] = theta
	//CurveFitDialog/ w[2] = const
	//CurveFitDialog/ w[3] = dS
	//CurveFitDialog/ w[4] = dT

	return (w[4])*((Vp-w[0])/(2*w[1])-0.5*w[3])*(cosh((Vp-w[0])/(2*w[1])))^(-2)+w[2]
End


function makeEntropyFitWave(dat,row,fitdata)
	wave dat, fitdata
	variable row


	make /O /N=(dimsize(dat,0)) datxval
	make /O /N=(dimsize(dat,0)) fitwave

	SetScale/P x dimoffset(dat,0),dimdelta(dat,0),"", datxval
	datxval =x
	SetScale/P x dimoffset(dat,0),dimdelta(dat,0),"", fitwave

	make /O /N=5 coefs
	coefs[0,4]=fitdata[row][p][0]

	int i=0
	variable x=0

	do
		fitwave[i]= Entropy1CK(coefs, datxval[i])
		i+=1
	while (i<dimsize(dat,0))

end

function seefit(row)
	variable row

	wave fitdata
	string datname
//	datname = "dat"+num2str(fitdata[0][5][0])+"Fastscanch1_2d" //grabs datnumber from fitdata
	datname = "dat"+num2str(fitdata[0][5][0])+"g1x2d" //grabs datnumber from fitdata
	wave loaddat=$datname  // sets dat to be dat...g2x2d
	duplicate/o loaddat, dat //To make g2x match fastscan
	wave fitwave
	//killwindow/Z SeeEntropyFit
	display/N=SeeEntropyFit dat[][row]
	makeentropyfitwave(dat,row,fitdata)
	appendtograph fitwave
	ModifyGraph rgb(fitwave)=(0,0,65535)
	//setaxis bottom fitdata[row][0][0]-15, fitdata[row][0][0]+15   // reasonable axis around centre point
	TextBox/C/N=text0/A=LT "Dat"+num2str(fitdata[0][5][0])+" BD13: "+num2str(fitdata[row][5][2])+"mV"
	Label left "EntropyX"
	Label bottom "FD_SDP/50mV"
End

function PlotEntropy([ErrorCutOff])

	variable ErrorCutOff
	wave fitdata
	variable i=0

	duplicate/O fitdata displaydata  //should make a wave with just the dimension it needs TODO

	if (paramisdefault(ErrorCutOff))
		errorcutoff = 0.5
	endif

	do
		if (fitdata[i][3][1] > errorcutoff || abs(fitdata[i][3][0]) > 10) // remove unreliable entropy values
			displaydata[i][3][0] = NaN
		endif
		i+=1
	while (i<dimsize(fitdata,0))

	setscale/P x, fitdata[0][5][2], (fitdata[1][5][2]-fitdata[0][5][2]), displaydata // sets scale to y scale of original data
	dowindow/K EntropyPlot
	display/N=EntropyPlot displaydata[][3][0]
	ErrorBars displaydata Y,wave=(displaydata[*][3][1],displaydata[*][3][1])
	Label left "Entropy/Kb"
	TextBox/C/N=text0/A=MT "dat"+num2str(fitdata[0][5][0]) //prints datnumber stored in 050
	Label bottom "BD13 /mV"
	make/O/N=(dimsize(displaydata,0)) tempwave = ln(2)
	setscale/P x, fitdata[0][5][2], (fitdata[1][5][2]-fitdata[0][5][2]), tempwave
	appendtograph tempwave
	ModifyGraph rgb(tempwave)=(0,0,65535), grid(bottom)=1,minor(bottom)=1,gridRGB(bottom)=(24576,24576,65535,32767), nticks(bottom)=10,minor=0

end


function fitcharge1D(dat)
	wave dat
	variable Vmid, w
	redimension/N=-1 dat
	duplicate/FREE dat datSmooth
	wavestats/Q/M=1 dat //easy way to get num notNaNs (M=1 only calculates a few wavestats)
	w = V_npnts/10 //width to smooth by (relative to how many datapoints taken)
	smooth w, datSmooth	//Smooth dat so differentiate works better
	differentiate datSmooth /D=datdiff
	wavestats/Q/M=1 datdiff
	Vmid = V_minloc

	Make/D/O/N=5 W_coef
	wavestats/Q/M=1/R=(Vmid-10,Vmid+10) dat //wavestats close to the transition (in mV, not dat points)
					//Scale y,   y offset, theta(width), mid, tilt
	w_coef[0] = {-(v_max-v_min), v_avg, 	abs((v_maxloc-v_minloc)/10), 	Vmid, 0} //TODO: Check theta is a good estimate
	duplicate/O w_coef w_coeftemp //TODO: make /FREE
	funcFit/Q Chargetransition W_coef dat /D
	wave w_sigma
	if(w_sigma[3] < 2) //Check Vmid was a good fit (Highly dependent on fridge temp and other dac values e.g. sometimes <0.03 consistently)
		return w_coef[3]
	endif
	make/O/N=2 cm_coef = 0
	duplicate/O/R=(-inf, vmid-5) dat datline //so hopefully just the gradient of the line leading up to the transition and not including the transition
	curvefit/Q line kwCWave = cm_coef datline /D
	w_coef = w_coeftemp
	w_coef[1] = cm_coef[0]
	w_coef[4] = cm_coef[1]
	funcFit/Q Chargetransition W_coef dat /D	//try again with new set of w_coef
	if	(w_sigma[3] < 0.5)
		return w_coef[3]
	else
		print "Bad Vmid = " + num2str(w_coef[3]) + " +- " + num2str(w_sigma[3]) + " near Vmid = " + num2str(Vmid)
		return NaN
	endif
end

function fitchargetransition(dat)
	// Takes 2D dat, puts fit paramters in fitwave
	wave dat

	variable G2, Vmid, G0, theta, gam
	variable i=0


//	make /O /N=(dimsize(dat,1)) datrow
	make /O/Free /N=(dimsize(dat,0)) datrow


//	SetScale/P x dimoffset(dat,1),dimdelta(dat,1),"", datrow
	SetScale/P x dimoffset(dat,0),dimdelta(dat,0),"", datrow

	Make/D/N=5/O W_coef
//	W_coef[0] = {0.1e-9,1.64e-9,3,-3412,0}

//	make /O /N=(dimsize(dat,0), 5) fitdata
	make/o/n=(dimsize(dat,1), 5) fitdata
	do
//		datrow[] = dat[i][p]
		datrow[] = dat[p][i]

		wavestats /Q datrow
		w_coef[0] = {(v_max-v_min), v_avg, 20, (v_maxLoc+(V_maxLoc-V_minLoc)/2),0}

		FuncFit /Q Chargetransition W_coef datrow /D

		fitdata[i][] = w_coef[q]
		i+=1
//	while (i<dimsize(dat, 0))
	while (i<dimsize(dat, 1))

End

Function Chargetransition(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = G0*tanh((x - Vmid)/(2*Theta)) + gamma*x + G2
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = G0
	//CurveFitDialog/ w[1] = G2
	//CurveFitDialog/ w[2] = Theta
	//CurveFitDialog/ w[3] = Vmid
	//CurveFitDialog/ w[4] = gamma

	return w[0]*tanh((x - w[3])/(2*w[2])) + w[4]*x + w[1]
End

//function makechargetransitionfit()
//	make/o/n=(numpnts(FastScan)) temp_transitionfit
//	variable i
//	for (i = 0; i < numpnts(FastScan); i++)
//		temp_transitionfit[i] = Chargetransition(fit_FastScan,
//	endfor
//end



function makecolorful([rev, nlines])
	variable rev, nlines
	variable num=0, index=0,colorindex
	string tracename
	string list=tracenamelist("",";",1)
	colortab2wave rainbow
	wave M_colors
	variable n=dimsize(M_colors,0), group
	do
		tracename=stringfromlist(index, list)
		if(strlen(tracename)==0)
			break
		endif
		index+=1
	while(1)
	num=index-1
	if( !ParamIsDefault(nlines))
		group=index/nlines
	endif
	index=0
	do
		tracename=stringfromlist(index, list)
		if( ParamIsDefault(nlines))
			if( ParamIsDefault(rev))
				colorindex=round(n*index/num)
			else
				colorindex=round(n*(num-index)/num)
			endif
		else
			if( ParamIsDefault(rev))
				colorindex=round(n*ceil((index+1)/nlines)/group)
			else
				colorindex=round(n*(group-ceil((index+1)/nlines))/group)
			endif
		endif
		ModifyGraph rgb($tracename)=(M_colors[colorindex][0],M_colors[colorindex][1],M_colors[colorindex][2])
		index+=1
	while(index<=num)
end




function udh5()
	// Loads HDF files back into Igor
	abort "This needs adapting so that it doesn't just load all files!"
	string infile = wavelist("*",";","") // get wave list
	string hdflist = indexedfile(data,-1,".h5") // get list of .h5 files

	string currentHDF="", currentWav="", datasets="", currentDS
	variable numHDF = itemsinlist(hdflist), fileid=0, numWN = 0, wnExists=0

	variable i=0, j=0, numloaded=0

	for(i=0; i<numHDF; i+=1) // loop over h5 filelist

	   currentHDF = StringFromList(i,hdflist)

		HDF5OpenFile/P=data /R fileID as currentHDF
		HDF5ListGroup /TYPE=2 /R=1 fileID, "/" // list datasets in root group
		datasets = S_HDF5ListGroup
		numWN = itemsinlist(datasets)
		currentHDF = currentHDF[0,(strlen(currentHDF)-4)]
		for(j=0; j<numWN; j+=1) // loop over datasets within h5 file
			currentDS = StringFromList(j,datasets)
			currentWav = currentHDF+currentDS
		   wnExists = FindListItem(currentWav, infile,  ";")
		   if (wnExists==-1)
		   	// load wave from hdf
		   	HDF5LoadData /Q /IGOR=-1 /N=$currentWav fileID, currentDS
		   	numloaded+=1
		   endif
		endfor
		HDF5CloseFile fileID
	endfor

   print numloaded, "waves uploaded"
end

