function y = output_cox_stats(stats, predictor_names)
  % displays results from coxphfit
    for i = 1:length(stats.beta)
        b_ci_lower = stats.beta(i) - 1.96 * stats.se(i);
        b_ci_upper = stats.beta(i) + 1.96 * stats.se(i);
        b = stats.beta(i);
        
        hr = exp( stats.beta(i) );
        hr_ci_lower = exp( b_ci_lower);
        hr_ci_upper = exp( b_ci_upper );
        disp(['  predictor: ' predictor_names{i} ';  b = ' num2str( b, '%.3f' ) ';  HR = ' num2str(hr, '%.2f') ' (' num2str(hr_ci_lower, '%.2f') ' - ' num2str(hr_ci_upper, '%.2f') ');  p = ' num2str(stats.p(i), '%.3f') ])
    if i==1
        first = struct('b', b, 'hr', hr, 'hr_ci_lower', hr_ci_lower, 'hr_ci_upper', hr_ci_upper);
        end
    end
    y = first;
end