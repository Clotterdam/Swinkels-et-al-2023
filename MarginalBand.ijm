dir = getDirectory("Choose the Directory");
fileNames=getFileList(dir);
Array.sort(fileNames);
File.makeDirectory(dir+"MarginalBand");
    
membranechannel = 1; //Channel for membrane stain (e.g. alpha-tubulin)
		                 
//Folder of TIF-files to read
for (ii=0; ii<fileNames.length; ii++){
	if(endsWith(fileNames[ii],".tif")){
		open(fileNames[ii]);
		rename("aaa");
		title = getTitle();
		nROI = roiManager("count");
		//Platelet selection section based on membrane or cytoskeleton staining
		//Iterations for Dilate/Erode may need to tuning for different stains
		//Different size particles for different microscope / resolution sizes
		//Autothreshold may need tuning for other staining concentrations etc.
		
		
		
if (nROI>0) {
	roiManager("select all")
	roiManager("delete")
		}
		
		//Segmentation of platelets
		selectWindow(title);
		run("Duplicate...", "duplicate channels="+membranechannel);
		dupmem = getTitle();
		run("Z Project...", "projection=[Average Intensity]");
		avgmem = getTitle();
		setAutoThreshold("Li dark");
		run("Convert to Mask");
		maskmem = getTitle();
		run("Options...", "iterations=2 count=1 black do=Dilate");
		run("Options...", "iterations=1 count=1 black do=[Fill Holes]");
		run("Options...", "iterations=2 count=1 black do=Erode");
		run("Watershed");
		setThreshold(255, 255);
		makeRectangle(3, 3, 1898, 1894);
		run("Crop");
		run("Analyze Particles...", "size=1000-16000 pixel circularity=0.2-1.00 exclude clear include add");
		close(dupmem);
		close(avgmem);
		close(maskmem);
		roiManager("Measure");	
		selectWindow("Results");
		saveAs("text", dir+"MarginalBand\\"+fileNames[ii]+"_MB.txt");
		close("Results");
		close("aaa");
	}
}

		