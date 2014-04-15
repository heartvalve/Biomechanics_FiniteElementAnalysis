# Execute using abaqus cae noGUI=scriptname.py

import os
wdir = 'H:\\Northwestern-RIC\\Modeling\\Abaqus\\Subjects\\'
import glob
filList = glob.glob(wdir+'*\\*.fil')

from abaqus import *
from abaqusConstants import *
session.Viewport(name='Viewport: 1', origin=(0.0, 0.0), width=261.16146440804, 
    height=215.4500182271)
session.viewports['Viewport: 1'].makeCurrent()
session.viewports['Viewport: 1'].maximize()
from viewerModules import *
from driverUtils import executeOnCaeStartup
executeOnCaeStartup()

for filFilename in filList:
    (pathToFile, ext) = os.path.splitext(filFilename)
    odbpathname = pathToFile+'.odb'
    o1 = session.openOdb(name=odbpathname)
    session.viewports['Viewport: 1'].setValues(displayedObject=o1)
    odb = session.odbs[odbpathname]
    session.viewports['Viewport: 1'].view.setValues(nearPlane=362.511, 
        farPlane=485.407, width=46.5183, height=51.6998, viewOffsetX=-2.63997, 
        viewOffsetY=11.7813)    
    leaf = dgo.Leaf(leafType=DEFAULT_MODEL)
    session.viewports['Viewport: 1'].odbDisplay.displayGroup.remove(leaf=leaf)
    leaf = dgo.LeafFromElementSets(elementSets=('PATELLACARTILAGE.PATELLACARTILAGE', ))
    session.viewports['Viewport: 1'].odbDisplay.displayGroup.add(leaf=leaf)    
    session.viewports['Viewport: 1'].odbDisplay.setPrimaryVariable(
        variableLabel='CPRESS', outputPosition=ELEMENT_NODAL)
    rptname = pathToFile+'_CPRESS_PatCart.rpt'  
    session.fieldReportOptions.setValues(printMinMax=OFF, printTotal=OFF)
    for framenum in range(21):
        try:
            session.writeFieldReport(fileName=rptname, append=ON, 
                sortItem='Node Label', odb=odb, step=1, frame=framenum, 
                outputPosition=ELEMENT_NODAL, variable=(('CPRESS', ELEMENT_NODAL), ))
        except:
            print 'The analysis has not completed'
    #
    rptfile = open(rptname)
    rptlist = rptfile.readlines()
    rptfile.close()
    os.remove(rptname)
    rptlist2 = []
    for i in range(len(rptlist)):
        rptline = rptlist[i]
        rptsplit = rptline.split()
        if len(rptsplit) == 4:
            if rptsplit[3] != '0.':
                rptlist2.append(rptline)
        else:
            rptlist2.append(rptline)
    newrpt = []
    for i in range(len(rptlist2)):
        rptline = rptlist2[i]
        rptsplit = rptline.split()
        if len(rptsplit) == 4:
            if rptsplit[1:] != newrpt[-1].split()[1:]:
                newrpt.append(rptline)
        else:
            newrpt.append(rptline)
    newrptfile = open(rptname,'w')
    newrptfile.writelines(newrpt)
    newrptfile.close()
