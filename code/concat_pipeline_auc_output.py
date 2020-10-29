import os
import argparse
import sys

parser = argparse.ArgumentParser(description='Provide model and taxonomy level')
parser.add_argument("--taxonomy", action ="store", dest="tax_level",
    help="Taxonomy options: kingdom, phylum, class, order, family, genus, otu, asv")
parser.add_argument("--model", action="store", dest="model",
    help= "Model options: rpart2, regLogistic, svmRadial, rf, xgbTree")

args = parser.parse_args()
tax_level = args.tax_level
model = args.model


search_dir = "data/"+tax_level+"/temp"
output_file = "data/process/combined-"+tax_level+"-"+model+".csv"

output = open(output_file, "w+" )
seed = 1

for file in os.listdir(search_dir):                             #loop over files in each taxonomy directory
    while seed <= 100:                                           #for all seed 100 files
        input_file = "data/"+tax_level+"/temp/"+model+"."+str(seed)+".csv"
        input = open(input_file,"r")
        if seed == 1:                                           #we want the header and the info
            lines = input.readlines()                           #read each line into a list
            output.write(lines[0].strip());output.write("\n")                     #write header to output file, strip off newline character
            output.write(lines[1].strip())                     #write auc data
        else:                                                   #we only want the file info
            lines = input.readlines()
            output.write(lines[1].strip())                     #append auc data to file
	output.write("\n")
        seed= seed+1                                            #increase seed tracker
        input.close()                                           #close the input file
    output.close()                                              #close output file
