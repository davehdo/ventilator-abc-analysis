

clear

param = "Duration of ICU Stay";
image_prefix = 'figure_icu_los_all_enrolles_adj';
outcome_description = 'Transferred out of ICU';
censor_description = 'death';
time_description = 'Days since ICU admission';

raw_table  = readtable('table_for_stats_package_analysis_all_enrolled_patients.csv');

% display the table's column names for reference
raw_table.Properties.VariableNames'

is_control = ismember(raw_table.state, 'control');
is_int = ismember(raw_table.state, 'intervention');
is_control_or_int = ~(~is_control .* ~is_int);

% CENSOR
% because patients who never left the unit should contribute to 
% length of stay as long as followed
% censor at the time of death (whenever the last hospital date is)
is_censored = ~ismember(raw_table.was_transferred_out_of_unit_after_this_int, 'true');

time_interval = cell_of_strings_to_numerical_array( raw_table.t_icu_adm_to_icu_dc_or_last_hosp_date );


disp(['Censoring ' censor_description ' and there are ' num2str(sum(is_censored .* is_control_or_int ))]);
disp(['  keeping ' num2str(sum(~is_censored .* is_control_or_int ))]);

values_all = time_interval(is_control_or_int);
values_control = time_interval( is_control);
values_int = time_interval( is_int );

censored_values_control = time_interval( and( is_control , ~is_censored));
censored_values_int = time_interval( and( is_int, ~is_censored) );

disp(['    control has ' num2str( length(censored_values_control) / length(values_control) ) ' censored']);
disp(['    int has ' num2str( length(censored_values_int) / length(values_int) ) ' censored']);



disp( '           Control       Intervention');
disp(['n          ' num2str(length(values_control)) '   ' num2str(length(values_int))]);
disp(['isnan      ' num2str( sum( isnan(values_control) ))  '    ' num2str( sum( isnan(values_int) )) ]);
disp(['means      ' num2str( nanmean(values_control) ) '     ' num2str( nanmean(values_int ) ) ]);
disp(['stdev      ' num2str( nanstd(values_control) ) '     ' num2str( nanstd(values_int ) ) ]);
disp(['n > 60     ' num2str( sum(values_control > 60 ) ) '     ' num2str( sum(values_int > 60) ) ]);
disp(['means cap60 ' num2str( mean_cap(values_control, 60) ) '     ' num2str( mean_cap(values_int, 60  ) ) ]);
disp(['stdev cap60 ' num2str( nanstd(cap(values_control, 60)) ) '     ' num2str( nanstd(cap(values_int, 60  )) ) ]);




predictor_names = {'Intervention group', 'APACHE IV Score', 'Was Pressor Dep'};
predictor_1 = ismember( raw_table.state( is_control_or_int), 'intervention');
predictor_2 = cell_of_strings_to_numerical_array( raw_table.apache_4( is_control_or_int) );
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
out = output_cox_stats( stats, predictor_names );

[b_unadj,logl_unadj,H_unadj,stats_unadj] = coxphfit( [ predictor_1 ], values_all, 'censoring', is_censored(is_control_or_int));        
disp('Cox Unadjusted');
output_cox_stats( stats_unadj, predictor_names );

[b_unadj_uncen,logl_unadj_uncen,H_unadj_uncen,stats_unadj_uncen] = coxphfit( [ predictor_1 ], values_all);        
disp('Cox Unadjusted, no censoring');
output_cox_stats( stats_unadj_uncen, predictor_names );

disp('t-test on log-time');

[h, ttest2_log_p, ci, ttest2_log_stats] = ttest2( log(values_int ), log(values_control), 'Tail', 'left');
disp(['  unadj, no censoring  m1 = ' num2str(mean( log(values_control))) '  m2 = ' num2str(mean( log(values_int)))  '  p = ' num2str(ttest2_log_p)] )

[h, ttest3_log_p, ci, ttest3_log_stats] = ttest2( log(censored_values_int ), log(censored_values_control), 'Tail', 'left');
disp(['  unadj, censored  m1 = ' num2str(mean( log(censored_values_control))) '  m2 = ' num2str(mean( log(censored_values_int)))  ' p = ' num2str(ttest3_log_p)] )


% coefficients


text( 4.8, 0.18, [ 'Hazard Ratio ' num2str(out.hr, '%.2f') ' (95% CI ' num2str(out.hr_ci_lower, '%.2f') '-' num2str(out.hr_ci_upper, '%.2f') ')'],'fontsize',14)
text( 4.8, 0.1, [ 'P = ' num2str(stats.p(1), '%.3f')], 'fontsize', 14)
%plot(0:1:25,1-cdf('wbl',0:1:25,4.63991,1.94422),':r')
% title(ax1, replace(param, '_', ' '));
xlabel({time_description});
ylabel(['Fraction of patients ' outcome_description]);
axis([0 21 0 1])
grid off
%         set(ax1,'xtick',0:400:50)
%         set(ax1,'ytick',0:1:0.2)
%         set(ax1,'xticklabels',0:400:50)
%         set(ax1,'yticklabels',0:1:0.2)
hold off

legend({'control','intervention'}, 'Location', 'northwest','fontsize',14 )

set( gca                       , ...
'FontName'   , 'Helvetica' );
set(gca, ...
'Box'         , 'off'     , ...
'TickDir'     , 'out'     , ...
'TickLength'  , [.02 .02] , ...
'YGrid'       , 'off'      , ...
'XColor'      , [.3 .3 .3], ...
'YColor'      , [.3 .3 .3], ...
'LineWidth'   , 1         );

% saveas( ax1, [param '.png']);
print( image_prefix  , '-dpng', '-r300')

        

