function [ output_args ] = cell_of_strings_to_numerical_array( cell_array )
%CELL_OF_STRINGS_TO_NUMERICAL_ARRAY Summary of this function goes here
%   when reading from a csv to a table, sometimes a few pesky empty
% cells cause the entire column to be interpreted as strings.
% conversion to numbers has trouble dealing with the blanks
% and therefore conversion to matrix fails
% this handles those blank values and makes them NaN in the final matrix.

% Convert all the blanks to NaNs
blanks = cellfun(@isempty,cell_array);

    tmp = ones( size( cell_array ) ) * -1;
    
    tmp( blanks ) = NaN;
    
    tmp( ~blanks ) = cellfun(@str2num,cell_array( ~blanks )) ;
    output_args = tmp; %cellfun(@str2num,cell_array)    
end