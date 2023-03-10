//Macro written to analyse data for the nanobody uptake experiments described in Swinkels et al. (2023)
//Segmentation of platelets followed by 3D object counter of VWF+ granules
//Using these as a mask where we measure the intensity of the other 2 (VWFpp + s-VWF) channels

dir = getDirectory("Choose the Directory");
fileNames=getFileList(dir);
Array.sort(fileNames);
File.makeDirectory(dir+"Results");
VWF = 1;		
PP = 2;		
nano = 3;	

//Forloop that opens all the images in one folder
for (ii=0; ii<fileNames.length; ii++){
		open(fileNames[ii]);
		getDimensions(width, height, channels, slices, frames);
		
//Output per Image as a tab separated file		
f = File.open(dir+"Results/Results_"+fileNames[ii]+".csv");
print(f,"roino\tObjectSize\tgranuleno\tintDen[0]\tmeanInt[0]\tintDen[1]\tmeanInt[1]\tintDen[2]\tmeanInt[2]");

//Segmentation of platelet area
run("Duplicate...", "duplicate channels=VWF");
vwfdup = getTitle();
run("Z Project...", "projection=[Max Intensity]");
maxProj = getTitle();
run("Gaussian Blur...", "sigma=6");
setAutoThreshold("Otsu dark");

run("Analyze Particles...", "size=10-Infinity pixel exclude clear include add");

counts=roiManager("count");
for(i=0; i<counts; i++) {
    roiManager("Select", i);
    run("Enlarge...", "enlarge=10 pixel");
    roiManager("Update");
    }
close(maxProj);
close(vwfdup);

//Save ROI locations in Results folder
roiManager("deselect")
roiManager("save", dir+ "ResultsV4/ROIs_"+fileNames[ii]+".zip")

//Forloop that goes over all platelets and identifies granules in the VWF channel
nRoi = roiManager("Count");
for(roino=0;roino<nRoi;roino++){
	roiManager("select", roino);
	
	run("Duplicate...","title=roi_"+roino+" duplicate");
	run("Split Channels");
	selectWindow("C1-roi_"+roino);
	getDimensions(width, height, channels, slices, frames);
	//Find the slice with the highest intensity to set the threshold on that slice
	maxSlice = 0;
	maxId = -1;
	for(i=1;i<=slices;i++){
		Stack.setPosition(1, i, 1);
		getStatistics(area, mean, min, max, std, histogram);
		if(mean>maxSlice){
			maxSlice = mean;
			maxId = i;
		}
	}
	
	Stack.setPosition(1, maxId, 1);
	setMinAndMax(0, 65535);
	setAutoThreshold("MaxEntropy dark no-reset");
	getThreshold(lower, upper);
	//print(lower,upper);
	run("3D Objects Counter", "threshold="+lower+" slice="+maxId+" min.=10 max.=224840 exclude_objects_on_edges objects");
	rename("obj_roi_"+roino);
	Stack.getStatistics(voxelCount, mean, min, max, stdDev);
	intDens = newArray(3);
	meanInt = newArray(3);
	print(max);
	for(i=1;i<=max;i++){
		selectWindow("obj_roi_"+roino);
		//Make a mask per granule and measure the intensity in the other channels
		setThreshold(i, i);
		run("Analyze Particles...", "size=0-Infinity pixel show=Masks include stack");
		rename("mask");
		Stack.getStatistics(voxelCount, mean);
		objectSize = voxelCount*mean;
		run("Divide...", "value=255 stack");
		for(channel=1;channel<=3;channel++){
			imageCalculator("Multiply create 32-bit stack", "mask" ,"C"+channel+"-roi_"+roino);
			rename("maskedGranule");
			Stack.getStatistics(voxelCount, mean);
			intDens[channel-1] = mean*voxelCount;
			meanInt[channel-1] = intDens[channel-1]/objectSize;
			close("maskedGranule");
		} 
		close("mask");
		print(f,""+roino+"\t"+objectSize+"\t"+i+"\t"+intDens[0]+"\t"+meanInt[0]+"\t"+intDens[1]+"\t"+meanInt[1]+"\t"+intDens[2]+"\t"+meanInt[2]);
		
	}
	close("obj_roi_"+roino);
	close("C1-roi_"+roino);
	close("C2-roi_"+roino);
	close("C3-roi_"+roino);
	showProgress(roino, nRoi-1);
}
File.close(f);
selectWindow("Log");
saveAs("Text", dir+ "Results/Log_"+fileNames[ii]+".zip");
close();
	}


//Continue analysis in R or Excel
//Empirically determine cut-off value for meanInt values


