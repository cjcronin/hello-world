function [ss,tt] = mwspeed(binsize, varargin)

%MWSPEED    Determine the time-dependent speed of a population of worms analyzed by the Goodman Lab multi-worm tracker.
%   FORMAT: mwspeed(binsize, firstTracksFile.mat, secondTracksFile.mat,..., NthTracksFile.mat)
%       where 
%       - binsize: The speed data from all analyzed worms are combined into
%         a single vector, but keeping track of the time point when each
%         speed measurement was recorded.  "mwspeed" breaks up the combined
%         speed vector into even-sized chunks of time, finding the mean and
%         variance information about the speed values in each chunk as an
%         individual unit of data for comparison with the values from each
%         other chunk of data.  Binsize describes the length, in seconds,
%         of those time chunks.
%       - *TracksFile.mat's are the names (with paths) of Matlab ".mat"
%         files generated by the Goodman Lab multi-worm tracker that
%         contain the Goodman Lab-defined "Tracks" structure.  To be used
%         by mwspeed, the Tracks structures in the .mat files should have
%         been analyzed to contain fields called Speed and Time for each
%         individual track.
%       and
%       - "ss" is the list of speed measurements from all of the worm
%         tracks listed in the input TracksFiles.mat, in monotonically
%         non-decreasing time order.
%       - "tt" is the list of time points associated with each speed
%         measurement in ss.
%
%   example:
%       [ss,tt] = mwspeed(60, ...
%           'G:\Data\Chris\2009_04_20\N2_day1.mat',...
%           'G:\Data\Chris\2009_04_21\N2_day2.mat',...
%           'G:\Data\Chris\2009_04_22\N2_day3.mat');
%       would combine all the multiple worm track recorded in those three
%       days' .mat files (each containing the necessary analyzed "Tracks"
%       structure into a single set of data, then find the mean speed
%       values for each 60-second period from the start of the first worm's
%       track through the end of the last worm's track.  The function
%       returns the speed and time values in ss and tt.
%
% - Christopher J. Cronin  (cjc@caltech.edu)
%   California Institute of Technology
%   Sternberg Lab
%   Pasadena, CA  USA
%   April 22, 2009

% Created for speed decay vs time work by Meenakshi Doma.


% Assemble matching speed and time vectors into a single vector

% Initialize intermidiate/output vectors
tt = [];
ss = [];

% Loop through each input .mat file
for j = 1:nargin-1
    t = [];
    s = [];
    
    % Place I/O stuff in try/catch statement for safety
    try
        load(varargin{j});
        
        if exist('Tracks', 'var') == 1  % Only care if Tracks is in the loaded .mat file
% disp(varargin{j});            
% disp(numel(Tracks));            
            for i = 1:numel(Tracks)
                t = [t Tracks(i).Time];
                s = [s Tracks(i).Speed];
                
                %             fprintf(1, 'Track: %2d  #Times: %4d   #Speeds: %4d\n', i, numel(Tracks(i).Time), numel(Tracks(i).Speed));
                %             figure; plot(Tracks(i).Time, Tracks(1).Speed, 'o');
%                             plot(Tracks(i).Time, Tracks(i).Speed, 'o-'); hold on;
            end
        else
            fprintf(1, 'No ''Tracks'' in %s.  Skipping...', varargin{j});
        end
        clear Tracks
        
        % Combine time and speed vectors
        tt = [tt, t];
        ss = [ss, s];
        
%         figure; plot(t, 'o-');
% %         figure; plot(t,s, 'o');
    catch ME
        fprintf(1, '%s\n', ME.message);
%         fprintf(1, '%s does not exist.  Skipping...\n', varargin{j});
%         %         warning(['No ''Tracks'' in ' varargin{j}])
    end
    
end

% Sort speed data against by time
[tt, ix] = sort(tt);
ss = ss(ix);

% figure; plot(tt,ss, 'ro');

% Create time bins
ttt = tt/binsize;
ttt = floor(ttt)*binsize;
ttt = ttt+binsize;
% ttt = ttt+(binsize/2);
bins = unique(ttt);

% Calculate statistics about sample sizes at each timepoint
uniqueTimepoints = unique(tt);
timepointsamplesizes = NaN*ones(size(uniqueTimepoints));
for k = 1:numel(uniqueTimepoints)
    timepointsamplesizes(k) = sum(tt == uniqueTimepoints(k));
end

% Combine timepoints into bins
meanBinnedTimepointSampleSize   = NaN*ones(size(bins));
maxBinnedTimepointSampleSize    = NaN*ones(size(bins));
minBinnedTimepointSampleSize    = NaN*ones(size(bins));

for k = 1:numel(bins)
    % figure out statistics for timepoints in each bin
    if k == 1
        meanBinnedTimepointSampleSize(k) = mean(timepointsamplesizes( uniqueTimepoints < bins(k)  ));
         maxBinnedTimepointSampleSize(k) =  max(timepointsamplesizes( uniqueTimepoints < bins(k)  ));
         minBinnedTimepointSampleSize(k) =  min(timepointsamplesizes( uniqueTimepoints < bins(k)  ));
    elseif k == numel(bins)
        meanBinnedTimepointSampleSize(k) = mean(timepointsamplesizes( uniqueTimepoints >=bins(k-1)));
         maxBinnedTimepointSampleSize(k) =  max(timepointsamplesizes( uniqueTimepoints >=bins(k-1)));
         minBinnedTimepointSampleSize(k) =  min(timepointsamplesizes( uniqueTimepoints >=bins(k-1)));
    else
        meanBinnedTimepointSampleSize(k) = mean(timepointsamplesizes((uniqueTimepoints >=bins(k-1)) & ...
                                                                     (uniqueTimepoints < bins(k)) ));
         maxBinnedTimepointSampleSize(k) =  max(timepointsamplesizes((uniqueTimepoints >=bins(k-1)) & ...
                                                                     (uniqueTimepoints < bins(k)) ));
         minBinnedTimepointSampleSize(k) =  min(timepointsamplesizes((uniqueTimepoints >=bins(k-1)) & ...
                                                                     (uniqueTimepoints < bins(k)) ));
    end
    
end


 meanspeed = NaN*ones(size(bins));
  stdspeed = NaN*ones(size(bins));
samplesize = NaN*ones(size(bins));

% Find characteristic values of each bin's data
for k = 1:numel(bins)
    meanspeed(k)  =  mean(ss(ttt==bins(k)));
     stdspeed(k)  =   std(ss(ttt==bins(k)));
    samplesize(k) = numel(ss(ttt==bins(k)));
    %     disp(ss(bins(k)));
end


% figure; plot(bins, meanspeed, 'bo-');
% figure; plot(bins, samplesize, 'ro-');

%----PLOT-SEM------------------------------------------------
figure; 
subplot(5,1, 1:4); 
errorbar(bins, meanspeed, stdspeed./sqrt(samplesize), 'bo-');
currentXLimits = get(gca, 'XLim');
currentYLimits = get(gca, 'YLim');
set(gca, 'XLim', [0 currentXLimits(2)]);
set(gca, 'YLim', [0 currentYLimits(2)]);
ylabel('Speed  [mm/sec]', 'FontWeight', 'bold');
legendtext = ['Mean speed over prior ' num2str(binsize) ' seconds, +/- 1 SEM'];
legend(legendtext);
set(gca, 'FontWeight', 'bold');


subplot(5,1,5); 
plot(bins, meanBinnedTimepointSampleSize, 'b.-');
hold on
plot(bins, [maxBinnedTimepointSampleSize;...
            minBinnedTimepointSampleSize],...
            'r-');
hold off
xlabel('Time  [sec]', 'FontWeight', 'bold');
ylabel({'# samples'; 'per time period'}, 'FontWeight', 'bold');



% Code to format plots for landscape output
set(gcf, 'PaperOrientation', 'Landscape');
set(gcf, 'PaperPosition', [0.25  0.25  10.5  8.0]);
set(gca, 'FontWeight', 'bold');

% To ensure color plot from Wormwriter Color
%   or grayscale plot from Wormwriter2
%   (was getting blank plots from ...2 and ...Color on 6/25/03
%   when plots were automatically setting to 'renderer' = 'zbuffer')
%   (Plots were also blank with 'renderer' = 'opengl'.)
set(gcf, 'Renderer', 'painters');

%----PLOT-SEM------------------------------------------------

%----PLOT-STD------------------------------------------------
figure; 
subplot(5,1, 1:4); 
errorbar(bins, meanspeed, stdspeed, 'bo-');
% errorbar(bins, meanspeed, stdspeed./sqrt(samplesize), 'bo-');
currentXLimits = get(gca, 'XLim');
currentYLimits = get(gca, 'YLim');
set(gca, 'XLim', [0 currentXLimits(2)]);
set(gca, 'YLim', [0 currentYLimits(2)]);
ylabel('Speed  [mm/sec]', 'FontWeight', 'bold');
legendtext = ['Mean speed over prior ' num2str(binsize) ' seconds, +/- 1 STD'];
% legendtext = ['Mean speed over prior ' num2str(binsize) ' seconds, +/- 1 SEM'];
legend(legendtext);
set(gca, 'FontWeight', 'bold');


subplot(5,1,5); 
plot(bins, meanBinnedTimepointSampleSize, 'b.-');
hold on
plot(bins, [maxBinnedTimepointSampleSize;...
            minBinnedTimepointSampleSize],...
            'r-');
hold off
xlabel('Time  [sec]', 'FontWeight', 'bold');
ylabel({'# samples'; 'per time period'}, 'FontWeight', 'bold');



% Code to format plots for landscape output
set(gcf, 'PaperOrientation', 'Landscape');
set(gcf, 'PaperPosition', [0.25  0.25  10.5  8.0]);
set(gca, 'FontWeight', 'bold');

% To ensure color plot from Wormwriter Color
%   or grayscale plot from Wormwriter2
%   (was getting blank plots from ...2 and ...Color on 6/25/03
%   when plots were automatically setting to 'renderer' = 'zbuffer')
%   (Plots were also blank with 'renderer' = 'opengl'.)
set(gcf, 'Renderer', 'painters');
%----PLOT-STD------------------------------------------------

%----PLOT----------------------------------------------------
figure; 
subplot(5,1, 1:4); 
plot(bins, meanspeed, 'bo-');
% errorbar(bins, meanspeed, stdspeed./sqrt(samplesize), 'bo-');
currentXLimits = get(gca, 'XLim');
currentYLimits = get(gca, 'YLim');
set(gca, 'XLim', [0 currentXLimits(2)]);
set(gca, 'YLim', [0 currentYLimits(2)]);
ylabel('Speed  [mm/sec]', 'FontWeight', 'bold');
legendtext = ['Mean speed over prior ' num2str(binsize) ' seconds'];
% legendtext = ['Mean speed over prior ' num2str(binsize) ' seconds, +/- 1 SEM'];
legend(legendtext);
set(gca, 'FontWeight', 'bold');


subplot(5,1,5); 
plot(bins, meanBinnedTimepointSampleSize, 'b.-');
hold on
plot(bins, [maxBinnedTimepointSampleSize;...
            minBinnedTimepointSampleSize],...
            'r-');
hold off
xlabel('Time  [sec]', 'FontWeight', 'bold');
ylabel({'# samples'; 'per time period'}, 'FontWeight', 'bold');



% Code to format plots for landscape output
set(gcf, 'PaperOrientation', 'Landscape');
set(gcf, 'PaperPosition', [0.25  0.25  10.5  8.0]);
set(gca, 'FontWeight', 'bold');

% To ensure color plot from Wormwriter Color
%   or grayscale plot from Wormwriter2
%   (was getting blank plots from ...2 and ...Color on 6/25/03
%   when plots were automatically setting to 'renderer' = 'zbuffer')
%   (Plots were also blank with 'renderer' = 'opengl'.)
set(gcf, 'Renderer', 'painters');
%----PLOT----------------------------------------------------
