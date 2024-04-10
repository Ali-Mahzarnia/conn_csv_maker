clear BATCH;

%variables

%bandpass filter -  allows a specific range of
%frequencies to pass through while attenuating frequencies outside the
%range - we do bandpass of 0 to 10
%
%pipeline does denoising (what is pipeline?) - we do the denoising -
%minimizing grainy spots and discoloration in images while minimizing loss
%of quality 
%ROI to ROI connectivity (resting state functional activity) -
%characterizes connectivity among pre-defind sets of regions
%can't do parallel processing with ICA but can do with seed-based
%ICA (independent component analysis) maps represent measures of different networks expression and
%connectivity at each voxel
%Can find the ICA for different subjects 
%Can change the p-value in the results 
%command conn_batch(BATCH) defubes experiment information and runs
%processing steps programmatically

project_name = 'conn_fmri_cardiac.mat';

n=30; %number of subjects
r=1; %number of runs (sessions)
TR = 2.252;

ICA_components = 20;
DYN_components = 20;
%import datasheet


%Setting up directories
input_dir = '/Users/bass/Desktop/output_fmri_pipeline/';
%input_dir1 = '/Users/bass/Desktop/output_T1_reoriented/';
input_dir1 = '/Users/bass/Desktop/fmri_all_to_batch5_conn/T1_atlas_regs/';
reference_dir = strcat(input_dir, 'outputs/');
fmri_dir = '/Users/bass/Desktop/fmri_all_to_batch5_conn/output_errts/'; %strcat(reference_dir, 'processed_fmri/');
%T1_dir = strcat(reference_dir, 'processed_T1/');
T1_dir = input_dir1;

%conn_batch(BATCH) saves a parameter file in the output location  --> goes
%into batch_filename

output_dir = '/Users/bass/Desktop/conn_tests_march/';

data = readtable("/Users/bass/Desktop/fmri_all_to_batch5_conn/coon_for_cardiac_30.csv" );
numRows = size(data, 1);
numCols = size(data, 2);
ID = data.('ID');

%Referencing maps
gm_mask_filename = strcat(reference_dir, 'reference_maps/', 'gm_mask.nii');
wm_mask_filename = strcat(reference_dir, 'reference_maps/', 'wm_mask.nii');
csf_mask_filename = strcat(reference_dir, 'reference_maps/', 'csf_mask.nii');
atlas_mask_filename = strcat(reference_dir,  'reference_maps/', 'chass_atlas_mask.nii');
atlas_filename = strcat(reference_dir,  'reference_maps/', 'chass_atlas.nii');
networks_filename = strcat(reference_dir,  'reference_maps/', 'amyg_hippo_olfactory.nii');

%roi_names = {'networks'; 'atlas'};
files = dir(strcat(reference_dir,  'reference_maps/', 'groups_2/', "*.nii.gz"));
roi_files = {};

for k = 4:length(files)
    roi_files{end+1} = strcat(reference_dir, 'reference_maps/', 'groups_2/', files(k).name);

end

%Defines filename
BATCH.filename = strcat(output_dir, project_name);

%Parallelization Options

%Creates new project
BATCH.Setup.isnew = 1;

%Repitition Time (TRs)
BATCH.Setup.RT = TR;

%Number of subjects
BATCH.Setup.nsubjects=n;

%Import functionals

for i = 1:n
	for j = 1:r
        func_filename = strcat(fmri_dir, ID(i), '_errts.nii.gz');
        BATCH.Setup.functionals{i}{j} = func_filename; %indexing into an array called functionals, character array of functional volume files 
		clear func_filename;
	end
end

%Import structurals
T1_filelist = dir(T1_dir);
for i = 1:n
	struc_filename = strcat(T1_dir, ID(i), '_regs.nii.gz');
	BATCH.Setup.structurals{i} = struc_filename;
	clear struc_filename;
end


%Import ROIs


for i = (1:length(roi_files))
    %BATCH.Setup.rois.names{i} = roi_names{i};
    BATCH.Setup.rois.files{i} = roi_files{i};
end

BATCH.Setup.masks.Grey = gm_mask_filename;
BATCH.Setup.masks.White = wm_mask_filename;
BATCH.Setup.masks.CSF = csf_mask_filename;

%Setup Erosion for Grey Matter, White Matter, CSF (in that order)
BATCH.Setup.binary_threshold = [.5 .5 .5];
BATCH.Setup.exclude_grey_matter = [nan, nan, nan];
BATCH.Setup.erosion_steps = [0 0 0];
BATCH.Setup.erosion.neighb = [1 1 1];

%Specify Conditions

%Specify Covariates (1st Level)

%Specify Covariates (2nd Level)

covariate_headers = data.Properties.VariableNames(2:end);
BATCH.Setup.subjects.effect_names = covariate_headers;
for i = (1:size(covariate_headers, 2))
    covariate = covariate_headers{i};
    covariate_data = data.(covariate);
    BATCH.Setup.subjects.effects{i} = covariate_data;
end




%Creates local copy of files
Setup.localcopy = 1;


%Analysis types: 1:ROI-to-ROI, 2:Seed-to-Voxel, 3:Voxel-to-Voxel, 4:Dyanmic FC
BATCH.Setup.analyses = [1,2,3,4];

%Voxel Resolution: 1:2mm, 2:same as structurals, 3:same as functionals, 4,surface-based template (Freesurfer)
BATCH.Setup.voxelresolution = 3;

%BOLD Signal units set to percent signal change
BATCH.Setup.analysisunits = 1;

%Set Analysis Mask
BATCH.Setup.voxelmask = 1;
BATCH.Setup.voxelmaskfile = atlas_mask_filename;


%{

%BATCH.Setup.preprocessing note: (NOT DOING THIS)

%Denoising

%NOTE: Ignore steps bcuz denoising was done in preproc pipeline. If you want denoising to be done, set BATCH.Denoising.done = 1 and edit options below.
BATCH.Denoising.detrending = 0;
BATCH.Denoising.despiking = 0;
BATCH.Denoising.regbp = 1;
BATCH.Denoising.confounds.names = ['Grey Matter', 'White Matter', 'CSF']; 
BATCH.Denoising.done = 0;

%Run First-level Analysis (ROI-to-ROI and Seed-to-Voxel)
BATCH.Analysis.done = 1;

%Group ICA
BATCH.vvAnalysis.name = 'ICA_01';
BATCH.vvAnalysis.measures = 'group-ICA';

%BATCH.vvAnalysis.measures.factors = ICA_components; %NOTE: not workixng??

%Dynamic ICA
BATCH.dynAnalysis.name = 'DYN_01';
BATCH.dynAnalysis.factors = DYN_components;

%}
%conn_batch(BATCH)