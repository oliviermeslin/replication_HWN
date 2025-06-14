//Follow the sequence outlined here when running the files. Run '3_tuning_dataset.do' during the first execution for tuning. For a deeper understanding of the machine learning coding, refer to Mullainathan & Spiess's work (https://www.aeaweb.org/articles?id=10.1257/jep.31.2.87), which forms the basis of this approach.

do $w5_prog/2_construct_estimation_data.do        
do $w5_prog/3_make_dataset_for_ml.do            
rsource using $w5_prog/ml/0_run_all.R, rpath("/usr/bin/R") roptions(`"--vanilla"') 
do $w5_prog/5aa_reassemble_ML.do       
do $w5_prog/5b_merge_back_ML.do        
do $w5_prog/0_rental_adjustment.do    
