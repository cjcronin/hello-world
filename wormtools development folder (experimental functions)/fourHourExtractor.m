function [] = fourHourExtractor(varargin)

% function [] = fourHourExtractor('directory1', 'directory2', ... 'directoryN')
% 
% This function is semi-customized for Cheryl van Buskirk to extract
% four-hour segments from long data sets.  Each 'directoryX' input should
% contain subfolders each containing a single 'worm1' folder (containing a
% file called veldata.mat generated by wormprocCheryl).  The function
% checks the recording length, asks for the 'entry point', the minute
% number where the four hours should begin, saves a backup copy of
% veldata.mat as veldata.mat.BKP, then extracts and saves the four-hour
% extraction back to veldata.mat.
%
% From: function [] = velPeeps(indir, varargin)
%
% Syntax:  [] = velPeeps(indir, varargin)
%    where:
% 'indir' = single directory of interest
% 'varargin' = list of folder prefixes in indir (e.g. 'N2_' for 'N2_*')
%
% Based (loosly) on: metrics6(mmpp, scnds, fpt, varargin)


%----------------------------------------------------------------
% Establish whether we Want to Definitely save for Matlab v6.x readability:
FORCE_to_v6 = 1;   % 1 = true, we want to save for v6 readability.
% Check for Matlab version
matlabversion = ver('MATLAB');
matlabversion = str2num(matlabversion.Version);

%----------------------------------------------------------------

fprintf(1,'\n');

% CONCEPT:   extracted = 1;  % Extracted flag = 'True' <-- save in veldata for future

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
if nargin<1
    error('Please give me an input directory to work on!  Toss me a bone, eh?')
end

% Constants:
secondsPerMinute = 60;  % Conversion
minutesPerHour = 60;    % Conversion
targetduration = 240;   % target extraction length (minutes)

for i = 1:nargin    % cycling through input directories
    % grab first directory name
    pd = varargin{i};
   
    % list contents of directory
%     d = dir([pd filesep groupname '*']);
    d = dir(pd);
    nd = prod(size(d));
    
%--------------------------------------------------------------------
    % Get rid of the '.' and '..' directories from the directory list   
    
    % Build up the list of baddies
    elimdirs = [];
    for j = 1:nd
        dirname = d(j).name;
        if (strcmp(dirname, '.')) | (strcmp(dirname, '..'))
            elimdirs = [elimdirs, j];
        end
    end
    
    % Blow away the baddies
    d(elimdirs) = [];
    
    % Reset the number of directories
    nd = prod(size(d));

%--------------------------------------------------------------------
    fprintf(1,'   Enter ''entry-point'' (minute number) for 4-hour extraction\n');
    fprintf(1,'   (e.g. Must be in the 0 - 120 minute range for a 6-hour recording)\n');
    fprintf(1,'   --To skip a worm just press ''Enter''--\n');
    
    for j = 1:nd    %cycle through each directory  matching groupname
        % get name of directory
        name = d(j).name;

        % clear variables
        clear durationminutes fingerprint fpt mmpp mode spf vel velc
        
        % Re-establish variable names
        mode    = [];
        vel     = [];
        velc    = [];
  
        % generate file name and path
        veldatafile = [pd filesep name filesep 'worm1' filesep 'veldata.mat'];

        % load in the data
        load(veldatafile);
        
        totalframes = numel(velc);  % NB: totalframes is actually the number 
                                    % of *extracted* frames (i.e. number of
                                    % timeblocks)
        
        % Sanity Check
        bestguessduration = totalframes * fpt * spf / (secondsPerMinute*minutesPerHour);
        if (bestguessduration>6.5) | (bestguessduration<5.5)
            fprintf(1,'\nHmmm, this looks more like a %d-hour recording.....\n',round(bestguessduration));
            fprintf(1,'    Perhaps did you already extract this one?  Press ''Enter'' to skip.\n');
%             fprintf(1,'\nHmmm, this worm doesn''t look right to me.\n');
%             fprintf(1,'    This looks like a %d-hour recording.  Be careful...\n',round(bestguessduration));
        end  % if bestguessduration doesn't smell right
        if ~exist('durationminutes')
            durationminutes = round(bestguessduration)*minutesPerHour;
        end % exist('durationminutes')        
        
        % Generate reference time vector based on recorded or guessed duration:
        timevector = [durationminutes/totalframes ...
                    : durationminutes/totalframes ...
                    : durationminutes];
        
        inputprompt = [name ' > '];
        entrypoint = input(inputprompt);
        if ~isempty(entrypoint)
            if entrypoint > durationminutes-targetduration
                error(['No can do, dude...  Entry point must be between 0 & ' int2str(durationminutes-targetduration) ' minutes...']);
            end % if entrypoint > possible
            
            if entrypoint < 0
                error('Hey, cool it!  How ''bout entering a number 0 or greater, hmm?  Thanks.');
            end % if entrypoint > possible
            
            if (entrypoint+targetduration) > timevector(end)
                error('Whoa, dude.  Something is seriously fouled up here.  Four hours after your entry point is beyond the end of your data set.');
            end % if (entrypoint+4hours is beyond end of data set
            % I think the previous two if's wind up being the same
        
            velc = velc( (timevector >= entrypoint) & (timevector <= (entrypoint+targetduration)) );
            vel  = vel ( (timevector >= entrypoint) & (timevector <= (entrypoint+targetduration)) );
            mode = mode( (timevector >= entrypoint) & (timevector <= (entrypoint+targetduration)) );
            
            % Reset durationminutes to targetduration (the extracted
            % length)
            durationminutes = targetduration;
            
            %-----------------------------------------------------
            % Save a backup copy of veldata.mat as veldata.mat.BKP
            copyfile(veldatafile, [veldatafile '.BKP']);
            %-----------------------------------------------------
            
            % Re-save metrics in file "veldata" 
            %   in input directory
            if ( FORCE_to_v6 & (matlabversion >= 7.0) )
                save([pd filesep name filesep 'worm1' filesep 'veldata.mat'], 'velc', 'fpt', 'vel', 'mode', 'spf', 'mmpp', 'durationminutes', 'fingerprint', '-v6');    
            else
                save([pd filesep name filesep 'worm1' filesep 'veldata.mat'], 'velc', 'fpt', 'vel', 'mode', 'spf', 'mmpp', 'durationminutes', 'fingerprint');    
            end
        else
            fprintf(1, '  Skipped\n');
        end %~isempty(entrypoint

    end  % for j = 1:nd

end % for i = 1:nargin-1

        
return


