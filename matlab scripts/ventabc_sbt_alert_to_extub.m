
clear

param = "time from SBT to extubation";
outcome_description = 'Extubated';
censor_description = 'anyone not extubated e.g. death and trach';
time_description = 'Days';

raw_table  = readtable('table_for_stats_package_analysis_all_enrolled_patients.csv');

% display the table's column names for reference
raw_table.Properties.VariableNames'

% see help file: Hazard and Survivor Functions for Different Groups

is_control = and(ismember(raw_table.state, 'control'), ismember(raw_table.was_sbt_alerted, 'true'));
is_int = and(ismember(raw_table.state, 'intervention'), ismember(raw_table.was_sbt_alerted, 'true'));
is_control_or_int = ~(~is_control .* ~is_int);

% CENSOR
is_censored = ~ismember(raw_table.vent_episode_outcome_was_extubated, 'true');
time_interval = cell_of_strings_to_numerical_array(raw_table.t_sbt_alert_to_extub_or_trach_or_death);
% is_censored = ismember(raw_table.did_die_on_vent_this_int, 'TRUE');

disp(['Censoring ' censor_description ' and there are ' num2str(sum(is_censored .* is_control_or_int ))]);
disp(['  Keeping ' num2str(sum(~is_censored .* is_control_or_int ))]);


values_all = time_interval(is_control_or_int);
values_control = time_interval( is_control);
values_int = time_interval( is_int );
post_censor_values_control = time_interval( and( is_control , ~is_censored));
post_censor_values_int = time_interval( and( is_int, ~is_censored) );


disp( '           Control       Intervention');
disp(['n          ' num2str(length(values_control)) '   ' num2str(length(values_int))]);
disp(['isnan      ' num2str( sum( isnan(values_control) ))  '    ' num2str( sum( isnan(values_int) )) ]);
disp(['means      ' num2str( nanmean(values_control) ) '     ' num2str( nanmean(values_int ) ) ]);
disp(['stdev      ' num2str( nanstd(values_control) ) '     ' num2str( nanstd(values_int ) ) ]);
disp(['n > 60     ' num2str( sum(values_control > 60 ) ) '     ' num2str( sum(values_int > 60) ) ]);
disp(['means cap60 ' num2str( mean_cap(values_control, 60) ) '     ' num2str( mean_cap(values_int, 60  ) ) ]);
disp(['stdev cap60 ' num2str( nanstd(cap(values_control, 60)) ) '     ' num2str( nanstd(cap(values_int, 60  )) ) ]);


disp(['  There are ' num2str(sum(isnan(time_interval( and( is_control_or_int, ~is_censored) )))) ' uncensored values that are NaN']);

predictor_names = {'Intervention group', 'APACHE IV Score', 'Was pressor dependent'};
predictor_1 = ismember( raw_table.state( is_control_or_int), 'intervention');
predictor_2 = cell_of_strings_to_numerical_array(raw_table.apache_4( is_control_or_int));
predictor_3 = ismember(raw_table.was_pressor_dependent(is_control_or_int), 'true');



figure
ax1 = gca;
[f0, x0] = ecdf(ax1,values_control,'function','survivor', 'censoring', is_censored(is_control));
stairs(x0, 1 - f0, 'LineWidth', 2)
hold on
[f,x] = ecdf(values_int,'function','survivor', 'censoring', is_censored(is_int)  );
stairs(x, 1 - f, 'LineWidth', 2 )


% predictors X, where T is either an n-by-1 vector or an n-by-2 matrix, and X is an n-by-p matrix.


[b,logl,H,stats] = coxphfit( [ predictor_1, predictor_2, predictor_3 ], values_all, 'censoring', is_censored(is_control_or_int));        

% b - e ^ b is the hazard
% logl - log likelihood value
% stats - The covariance matrix of the coefficient estimates

disp(['Outcome: ' outcome_description]);
disp('Cox Adjusted by APACHE IV:');
output_cox_stats( stats, predictor_names );

[b_unadj,logl_unadj,H_unadj,stats_unadj] = coxphfit( [ predictor_1 ], values_all, 'censoring', is_censored(is_control_or_int));        
disp('Cox Unadjusted');
output_cox_stats( stats_unadj, predictor_names );

[b_unadj_uncen,logl_unadj_uncen,H_unadj_uncen,stats_unadj_uncen] = coxphfit( [ predictor_1 ], values_all);        
disp('Cox Unadjusted, no censoring');
output_cox_stats( stats_unadj_uncen, predictor_names );

disp('t-test on log-time');

disp(['  Warning: there are ' num2str(sum([ values_int;  values_control] <= 0) ) ' values <= 0']);
disp(['    there are ' num2str(sum([post_censor_values_int; post_censor_values_control] <= 0) ) ' post-censoring values <= 0']);

[h, ttest2_log_p, ci, ttest2_log_stats] = ttest2( log(values_int( values_int > 0) ), log(values_control(values_control > 0)), 'Tail', 'left');
disp(['  unadj, no censoring  p = ' num2str(ttest2_log_p)] )


[h, ttest3_log_p, ci, ttest3_log_stats] = ttest2( log(post_censor_values_int( post_censor_values_int > 0) ), log(post_censor_values_control(post_censor_values_control > 0)), 'Tail', 'left');
disp(['  unadj, censored   p = ' num2str(ttest3_log_p)] )
% raw_table.t_sbt_alert_to_final_extub_or_trach <= 0

% coefficients


text( 4.8, 0.18, [ 'Cox p = ' num2str(stats.p(1))])
text( 4.8, 0.1, ['t-test on log-time' ' p = ' num2str(ttest2_log_p)] )
%plot(0:1:25,1-cdf('wbl',0:1:25,4.63991,1.94422),':r')
title(ax1, replace(param, '_', ' '));
xlabel({time_description});
ylabel(['Fraction of patients ' outcome_description]);
axis([0 21 0 1])
grid off
%         set(ax1,'xtick',0:400:50)
%         set(ax1,'ytick',0:1:0.2)
%         set(ax1,'xticklabels',0:400:50)
%         set(ax1,'yticklabels',0:1:0.2)
hold off
legend('control','intervention', 'Location', 'northwest' )

set( gca                       , ...
'FontName'   , 'Helvetica' );
set(gca, ...
'Box'         , 'off'     , ...
'TickDir'     , 'out'     , ...
'TickLength'  , [.02 .02] , ...
'YGrid'       , 'on'      , ...
'XColor'      , [.3 .3 .3], ...
'YColor'      , [.3 .3 .3], ...
'LineWidth'   , 1         );

% saveas( ax1, [param '.png']);

        

