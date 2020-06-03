function pinchtest(bd, start, fin, channels, numpts, delay, ramprate, current_wave, cutoff_nA, gates_str)
	/// For testing pinch off (10/2/2020)
	// Make sure current wave is in nA
	variable bd, start, fin, numpts, delay, ramprate, cutoff_nA
	string channels, current_wave, gates_str
	rampmultiplebd(bd, channels, 0, ramprate=ramprate)
	string comment
	sprintf comment, "pinch, gates=(%s)", gates_str
	ScanBabyDACUntil(bd, start, fin, channels, numpts, delay, ramprate, current_wave, cutoff_nA, operator="<", comments=comment)
	rampmultiplebd(bd, channels, 0, ramprate=ramprate)
end


function SetupStandardEntropy([printchanges, keepphase])
//TODO: This can be simplified with the load from HDF File
	variable printchanges, keepphase
	//Sets HQPC, SRSfreq, SRStconst, SRSsensitivity, Magy, FD
	nvar bd6, fastdac, srs1, srs2, magy, srs4, dmm5, magz, magy
	variable SRSout = 350, SRSfreq=111.11, SRStconst=0.03, SRSsens = 100, SRSphase=90, HQPC = -960, fieldy = 20, DCheat = 0

	variable temp
	string tempstr
	CheckInstrIds(bd6, fastdac, srs1, srs2, srs4, dmm5, magz, magy)
	temp = getsrsamplitude(srs1)
	if (temp != SRSout)
		if (printchanges)
			printf "Changing SRS1out from %.1fmV to %.1fmV\r", temp, SRSout
		endif
		setsrsamplitude(srs1, SRSout)
	endif
	temp = getsrsphase(srs1)
	if (temp != SRSphase && keepphase == 0)
		if (printchanges)
			printf "Changing SRS1phase from %.1f to %.1f\r", temp, SRSphase
		endif
		setsrsphase(srs1, SRSphase)
	else
		printf "SRS1 phase left at %.1f\r", temp
	endif
	temp = getsrsfrequency(srs1)
	if (temp != SRSfreq)
		if (printchanges)
			printf "Changing SRS1freq from %.1fHz to %.1fHz\r", temp, SRSfreq
		endif
		setsrsfrequency(srs1, SRSfreq)
	endif
	temp = getsrstimeconst(srs1)
	if (temp != SRStconst)
		if (printchanges)
			printf "Changing SRS1tconst from %.3fs to %.3fs\r", temp, SRStconst
		endif
		setsrstimeconst(srs1, SRStconst)
	endif
	temp = getsrstimeconst(srs4)
	if (temp != SRStconst)
		if (printchanges)
			printf "Changing SRS4tconst from %.3fs to %.3fs\r", temp, SRStconst
		endif
		setsrstimeconst(srs4, SRStconst)
	endif
	temp = getsrssensitivity(srs1)
	if (temp != SRSsens)
		if (printchanges)
			printf "Changing SRS1sensitivity from %.1fmV to %.1fmV\r", temp, SRSsens
		endif
		setsrssensitivity(srs1, SRSsens)
	endif
	temp = getsrssensitivity(srs4)
	if (temp != SRSsens)
		if (printchanges)
			printf "Changing SRS4sensitivity from %.1fmV to %.1fmV\r", temp, SRSsens
		endif
		setsrssensitivity(srs4, SRSsens)
	endif
	temp = getls625field(magy)
	if ((temp-fieldy)>0.05)
		if (printchanges)
			printf "Changing Magy from %.1fmT to %.1fmT\r", temp, fieldy
		endif
		setls625fieldwait(magy, fieldy)
	endif
	wave/t old_dacvalstr
	tempstr = old_dacvalstr[15]
	if (str2num(tempstr) != HQPC)
		if (printchanges)
			printf "Changing HQPC from %smV to %.1fmV\r", tempstr, HQPC
		endif
		rampmultiplebd(bd6, "15", HQPC)
	endif
	tempstr = old_dacvalstr[3]
	if (str2num(tempstr) != DCheat)
		if (printchanges)
			printf "Changing DCheat from %smV to %.1fmV\r", tempstr, DCheat
		endif
		rampmultiplebd(bd6, "3", DCheat)
	endif
	if (str2num(tempstr) != 0)
		if (printchanges)
			printf "Changing DCbias(DAC3) from %smV to 0mV\r", tempstr
		endif
		rampmultiplebd(bd6, "3", 0)
	endif

end
