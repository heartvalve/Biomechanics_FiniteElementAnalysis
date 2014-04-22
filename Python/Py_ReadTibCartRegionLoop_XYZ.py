import os
import glob
import re


wdir = 'H:\\Northwestern-RIC\\Modeling\\Abaqus\\'

ltcfile = open(wdir+'GenericFiles\\Nodes_LTIBIACARTILAGE-Region.data')
ltclist = ltcfile.readlines()
ltcfile.close()
mtcfile = open(wdir+'GenericFiles\\Nodes_MTIBIACARTILAGE-Region.data')
mtclist = mtcfile.readlines()
mtcfile.close()

lnode_num = []; lnode_xyz = []
for i in range(len(ltclist)):
    ltcline = ltclist[i]
    lnode_num.append(ltcline.split(',',1)[0].strip())
    lnode_xyz.append(ltcline.split(',',1)[1].strip())
lnode2xyz = dict(zip(lnode_num,lnode_xyz))
mnode_num = []; mnode_xyz = []
for i in range(len(mtclist)):
    mtcline = mtclist[i]
    mnode_num.append(mtcline.split(',',1)[0].strip())
    mnode_xyz.append(mtcline.split(',',1)[1].strip())
mnode2xyz = dict(zip(mnode_num,mnode_xyz))
    
lrptfilepath = wdir+'*\\*\\*CPRESS*Lat*.rpt'
lrptfilelist = glob.glob(lrptfilepath)
mrptfilepath = wdir+'*\\*\\*CPRESS*Med*.rpt'
mrptfilelist = glob.glob(mrptfilepath)


for lrptfilename in lrptfilelist:

    rptfile = open(lrptfilename)
    rptlist = rptfile.readlines()
    rptfile.close()   

    start = []; end = []; stime = []
    for i in range(len(rptlist)):
        rptline = rptlist[i]
        if rptline == '-----------------------------------------------------------------\n':
            start.append(i+1)
        elif rptline == '********************************************************************************\n':
            if i != 0:
                end.append(i-3)
        elif len(re.findall('Step Time = ',rptline)) > 0:
            stime.append(rptline.split()[-1])
    end.append(len(rptlist)-3)

    output = []
    output.append('Time\tX\tY\tZ\tCPress\n')
    for i in range(len(stime)):        
        for j in range(start[i],end[i]+1):
            node = rptlist[j].split()[2]
            if node in lnode2xyz:
                xyz = lnode2xyz[node]
                x = xyz.split(',')[0].strip()
                y = xyz.split(',')[1].strip()
                z = xyz.split(',')[2].strip()
                cp = rptlist[j].split()[-1].strip()
                output.append(stime[i]+'\t'+x+'\t'+y+'\t'+z+'\t'+cp+'\n')
            
    outrptfile = open(lrptfilename[:-4]+'-Region.data','w')
    outrptfile.writelines(output)
    outrptfile.close()

for mrptfilename in mrptfilelist:

    rptfile = open(mrptfilename)
    rptlist = rptfile.readlines()
    rptfile.close()   

    start = []; end = []; stime = []
    for i in range(len(rptlist)):
        rptline = rptlist[i]
        if rptline == '-----------------------------------------------------------------\n':
            start.append(i+1)
        elif rptline == '********************************************************************************\n':
            if i != 0:
                end.append(i-3)
        elif len(re.findall('Step Time = ',rptline)) > 0:
            stime.append(rptline.split()[-1])
    end.append(len(rptlist)-3)

    output = []
    output.append('Time\tX\tY\tZ\tCPress\n')
    for i in range(len(stime)):        
        for j in range(start[i],end[i]+1):
            node = rptlist[j].split()[2]
            if node in mnode2xyz:
                xyz = mnode2xyz[node]
                x = xyz.split(',')[0].strip()
                y = xyz.split(',')[1].strip()
                z = xyz.split(',')[2].strip()
                cp = rptlist[j].split()[-1].strip()
                output.append(stime[i]+'\t'+x+'\t'+y+'\t'+z+'\t'+cp+'\n')
            
    outrptfile = open(mrptfilename[:-4]+'-Region.data','w')
    outrptfile.writelines(output)
    outrptfile.close() 

print 'Run is complete'
