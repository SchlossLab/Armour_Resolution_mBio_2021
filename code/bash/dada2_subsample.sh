#!/bin/bash

bin/mothur/mothur "#set.dir(output=data/dada2);
                   sub.sample(shared=data/dada2/asv_table.shared, size=10500)"
