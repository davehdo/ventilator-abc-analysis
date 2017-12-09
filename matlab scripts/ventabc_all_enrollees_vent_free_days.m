



clear

outcome_description = 'leave ICU';
censor_description = 'died in ICU or discharged from ICU';
time_description = 'Days';

raw_table  = readtable('table_for_stats_package_analysis_all_enrolled_patients.csv');

% display the table's column names for reference
% raw_table.Properties.VariableNames'

% see help file: Hazard and Survivor Functions for Different Groups

is_control = ismember(raw_table.state, 'control');
is_int = ismember(raw_table.state, 'intervention');
is_control_or_int = ~(~is_control .* ~is_int);

% possible outcomes


% 
outcomes(1).name = 'Vent free days';
tmp = cell_of_strings_to_numerical_array( raw_table.vent_free_trach_free_days_28d_cap_set_death_to_zero );

% change the zeros
tmp( tmp <= 0 ) = 0.1;

% what is this step for?
% there are rare NaNs that make mean and stdev not work
% tmp( isnan(tmp) ) = 0.1;

outcomes(1).classifications = tmp;


predictor_names = {'Intervention group', 'APACHE IV Score', 'Was Pressor Dep', 'age'};
predictor_1 = ismember( raw_table.state( is_control_or_int), 'intervention') .* 1.0;
predictor_2 = cell_of_strings_to_numerical_array( raw_table.apache_4( is_control_or_int));
predictor_3 = ismember(raw_table.was_pressor_dependent(is_control_or_int), 'true') .* 1.0;
% predictor_4 = raw_table.AGE(is_control_or_int) >  70;



for i = 1:length(outcomes)
    disp(outcomes(i).name);
%     [B,dev,stats] = glmfit([ predictor_1, predictor_2, predictor_3 ], outcomes(i).classifications(is_control_or_int), 'poisson');

%     n_cols = size(B, 2);
    
    control_values = outcomes(i).classifications( is_control);
    int_values = outcomes(i).classifications(is_int );
    
    
    disp('       CONTROL         INTERVENTION');
    disp(['n      ' num2str(length(control_values)) '        ' num2str(length(int_values)) ]);
    disp(['n nans ' num2str( sum( isnan(control_values) ) ) '        ' num2str(sum(isnan(int_values))) ]);
    disp(['mean   ' num2str( nanmean( control_values ) ) '        ' num2str(nanmean(int_values)) ]);
    disp(['stdev  ' num2str( nanstd( control_values ) ) '        ' num2str(nanstd(int_values)) ]);
    

    [h,p,ci,ttest_stats] = ttest2( control_values, int_values );
    disp(' ' );
    disp(['  t test: p = ' num2str(p)]);
    p_ranksum = ranksum( control_values, int_values )
    

end
