


clear


raw_table  = readtable('table_for_stats_package_analysis_all_enrolled_patients.csv','TreatAsEmpty',{''});

% display the table's column names for reference
% raw_table.Properties.VariableNames'

% see help file: Hazard and Survivor Functions for Different Groups

is_control = and(ismember(raw_table.state, 'control'), ismember( raw_table.was_sbt_alerted, 'true' ));
is_int = and(ismember(raw_table.state, 'intervention'), ismember( raw_table.was_sbt_alerted, 'true' )) ;
is_control_or_int = ~(~is_control .* ~is_int);

% possible outcomes
outcomes(1).name = 'Vent Episode outcome = Extubated';
outcomes(1).classifications = true_false_nan(raw_table.vent_episode_outcome_was_extubated );

outcomes(2).name = 'Vent Episode outcome = Trached';
outcomes(2).classifications = true_false_nan(raw_table.vent_episode_outcome_was_trach );
 
outcomes(3).name = 'Vent Episode outcome = Expired';
outcomes(3).classifications = true_false_nan(raw_table.vent_episode_outcome_was_died ); 
% 


ve_outcome = nan( size( raw_table.vent_episode_outcome_was_extubated ) );
ve_outcome( outcomes(1).classifications == 1 ) = 3; % 'E';
ve_outcome( outcomes(2).classifications == 1 ) = 2; %'T';
ve_outcome( outcomes(3).classifications == 1 ) = 1; % 'D';


outcomes(4).name = 'Visit outcome = Trach free survival';
outcomes(4).classifications = true_false_nan(raw_table.visit_outcome_was_trach_free_survival );
% 
outcomes(5).name = 'Visit outcome = survival w/ trach';
outcomes(5).classifications = true_false_nan(raw_table.visit_outcome_was_surv_with_trach );
% 
outcomes(6).name = 'Visit outcome = Expired';
outcomes(6).classifications = true_false_nan(raw_table.visit_outcome_was_expired ); 
% 


predictor_names = {'Intervention group', 'APACHE IV Score', 'Was Pressor Dep' };
predictor_1 = ismember( raw_table.state( is_control_or_int), 'intervention') .* 1.0;
predictor_2 = cell_of_strings_to_numerical_array(raw_table.apache_4( is_control_or_int));
predictor_3 = true_false_nan(raw_table.was_pressor_dependent(is_control_or_int) ) .* 1.0;
% predictor_4 = raw_table.AGE(is_control_or_int) >  70;


disp('first attempting pearson chi-sq test')


x = predictor_1; % not treated, treated 
y = ve_outcome(is_control_or_int); 
[table, chi2, p] = crosstab(x,y);
disp(['  chi2 is ' num2str(chi2) ]);
df = 2;
p = chi2cdf(chi2 ,df,'upper') ;
disp(['  the p-value is ' num2str(p)  ])


disp('first attempting response variable with 3 options for ve outcome, and therefore OR will be to reference');
[B,dev,stats] = mnrfit([ predictor_1, predictor_2, predictor_3 ], categorical( ve_outcome(is_control_or_int) ));
stats.p(2, :)
    % the first column is odds died/extubated
    % the second column is odds trached/extubated
    % coeff -0.2530   -0.3480
    % p values =  0.4758    0.3697

    
disp('now attempting binary response variables for each outcome individually');

for i = 1:length(outcomes)
    disp(outcomes(i).name);
    
    % logistic regression
    [B,dev,stats] = mnrfit([ predictor_1, predictor_2, predictor_3 ], categorical(outcomes(i).classifications(is_control_or_int)));

    n_cols = size(B, 2);
    
    int_values = outcomes(i).classifications(is_int );
    control_values = outcomes(i).classifications(is_control );
    
    p = nanmean([control_values; int_values]);
    p1 = nanmean(control_values);
    p2 = nanmean(int_values);
    n1 = sum(~isnan(control_values));
    n2 = sum(~isnan(int_values));
    z = (p1 - p2) / sqrt(p * (1 - p) * ( 1 / n1 + (1 / n2)));
    
    if z > 0
        p_val = 1 - tcdf(z,n1 + n2 -1);
    else
        p_val = tcdf(z,n1 + n2 -1);
    end

    if n_cols == 1
        % means it was a binary outcome
        output_multinomial_logstic_stats( stats, control_values, int_values );
    else
       for j = 1:n_cols
           disp(['  comparing outcome ' num2str(j) ' versus ' num2str( n_cols + 1) ]);
           output_multinomial_logstic_stats( struct( 'beta', stats.beta(:, j), 'se', stats.se(:, j), 'p', stats.p(:, j)), control_values, int_values );
       end
    end
    
        
    disp(['  t-test 1-tailed:  P = ' num2str(p_val, 3) ]);


% first row contains the constants
% second row contains coefficients for predictor 1

% coefficients represent k in the following formula
% y = k1 X1 + k2 X2 + k3 X3 + k0
% where y = log odds of being in one category versus the reference category
% thus ks should represent odds ratios


end

