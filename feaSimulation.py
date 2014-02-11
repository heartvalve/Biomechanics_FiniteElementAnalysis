"""
----------------------------------------------------------------------
    feaSimulation.py
----------------------------------------------------------------------
    This module can be used to run a single FEA simulation from an
    input file. It will display messages to the user to indicate if
    the simulation was successful.
    
    Input:
        Simulation name
    Output:
        Simulation results
----------------------------------------------------------------------
    Created by Megan Schroeder
    Last Modified 2014-02-11
----------------------------------------------------------------------
"""


# Imports
import os
import subprocess
import time


class feaSimulation:
    """
    A class to run a given FEA simulation from an input file
    """
    
    def __init__(self,simName):
        """
        Create an instance of the class from the simulation name and
        add directory paths to be referenced
        """
        # Subject ID
        self.subID = simName.split('_')[0]
        # Subject directory
        nuDir = os.getcwd()
        while os.path.basename(nuDir) != 'Northwestern-RIC':
            nuDir = os.path.dirname(nuDir)
        #self.subDir = os.path.join(nuDir,'Modeling','Abaqus','Subjects',self.subID)+'\\'
        self.subDir = os.path.join(nuDir,'SVN','Working','FiniteElement','Subjects',self.subID)+'\\'
        # Simulation name
        self.simName = simName
        # Subroutine directory
        self.userDir = os.path.join(nuDir,'SVN','Working','FiniteElement','UserSubroutines')+'\\'
            
    """------------------------------------------------------------"""
    def copyINPtoSubFolder(self):
        """
        Create a subfolder for each simulation and place a copy of
        the input file there (with path adjustments)
        """
        # Create temporary folder
        os.mkdir(self.subDir+self.simName)
        # Read the input file
        inpFile = open(self.subDir+self.simName+'.inp')
        inpString = inpFile.read()
        inpFile.close()        
        # Replace string
        newInpString = inpString.replace('../../','../../../')        
        # Write new file to temporary folder
        newInpFile = open(self.subDir+self.simName+'\\'+self.simName+'.inp','w')
        newInpFile.write(newInpString)
        newInpFile.close()        
    
    """------------------------------------------------------------"""
    def executeShell(self):
        """
        Run via the command prompt
        """
        # Open subprocess in current directory (subfolder)
        subprocess.Popen(('abaqus job='+self.simName+' user='+self.userDir+'vuamp_vumat.for'), shell=True, cwd=(self.subDir+self.simName))        
    
    """------------------------------------------------------------"""
    def checkIfDone(self):
        """
        Check if the simulation is finished
        """
        # Starting time
        startTime = time.time()
        # Wait
        time.sleep(15)
        # Display message
        print ('Waiting for '+self.simName+' to complete.')
        # Loop
        while True:
            # Check for lck file (still running)
            if os.path.isfile(self.subDir+self.simName+'\\'+self.simName+'.lck'):
                time.sleep(15)
            # Simulation is finished
            else:
                simTime = int((time.time()-startTime)/60)
                print (self.simName+': time elapsed = '+str(simTime)+' minutes.')
                break

    """------------------------------------------------------------"""            
    def checkStatus(self):
        """
        Check if the simulation succeeded or crashed
        """
        # Check the status file 
        staFile = open(self.subDir+self.simName+'\\'+self.simName+'.sta')
        staString = staFile.read()
        staFile.close()
        if 'THE ANALYSIS HAS COMPLETED SUCCESSFULLY' in staString:
            print (self.simName+': has completed successfully.')
        else:
            print (self.simName+': failed. Check status file.')
        
    """------------------------------------------------------------"""
    def cleanUp(self):
        """
        Delete unnecessary files created during the simulation run
        """
        pass
        
    """------------------------------------------------------------"""
    def moveResultsToMain(self):
        """
        Move the simulation results to the main subject directory
        """
        # Delete input file
        os.remove(self.subDir+self.simName+'\\'+self.simName+'.inp')
        # Move files
        allFiles = os.listdir(self.subDir+self.simName+'\\')
        for fName in allFiles:
            os.rename(self.subDir+self.simName+'\\'+fName, self.subDir+fName)
        # Delete (empty) simulation folder
        os.rmdir(self.subDir+self.simName)
        # Brief pause
        time.sleep(1)
        
    """------------------------------------------------------------"""
    def run(self):
        """
        Main program to run an individual simulation
        """
        self.copyINPtoSubFolder()
        self.executeShell()
        self.checkIfDone()
        self.checkStatus()
        self.cleanUp()
        self.moveResultsToMain()
