%% PlotFilmExtrusion: Authored by David Kazmer, June 3, 2024
% Uses downloaded data from Dr. Collin Teachline 
% Plots with image data, optional video
% Written for processing on extruder 3 with Ex 1 P as die pressure

% Set option to make movie
bSaveMovie=true;
PNGFolder='20240530 Five POs (PP,PE,PE-PP,PP1,PP2)\';

% If table process data not already loaded, load data
if ~exist('T')
    T=readtable('20240530 Five POs (PP,PE,PE-PP,PP1,PP2).xls');
    % Convert time strings to time iune
    T.Time=posixtime(datetime(T.Time, 'InputFormat', 'dd/MM/yyyy HH:mm:ss'));
    % Record t0 as time of process start
    t0=T.Time(1);
    % Convert table to matrix of doubles
    d=table2array(T);
    % Subtract start time from 
    d(:,1)=d(:,1)-d(1,1);
end

% If image file data not already loaded, then load
if ~exist('AllFiles')
    AllFiles=dir('20240530 Five POs (PP,PE,PE-PP,PP1,PP2)\*.png');
    % Create field with time of image
    for i = 1:numel(AllFiles)
        % Extract the date portion from the file name
        dateStr = extractBetween(AllFiles(i).name, ' - ', '.png');
        
        % Convert the date string to a datetime object
        dateObj = datetime(dateStr, 'InputFormat', 'yyyy-MM-dd HH-mm-ss');
        
        % Add the POSIX time to the struct
        AllFiles(i).time = posixtime(dateObj)-t0;
        FileTimes=[AllFiles.time];
    end
end

% Define processing states of interest
StateNames{1}='Ex3 Temp, C';iState(1)=31;Style{1}='m-';
StateNames{2}='Ex3 Speed, RPM';iState(2)=32;Style{2}='k-';
StateNames{3}='Ex3 Pres, bar';iState(3)=30;Style{3}='r-';
StateNames{4}='Die Pres, bar';iState(4)=7;Style{4}='b-';

% Create figure with all states across time
figure(1);clf;hold on

% Define areas of interest for further plotting
dt=900;         % Assume fifteen minutes (OK to change)
i1=[2500 7020 9940 12900 16500];i2=i1+dt;
Grades{1}=' PP ';
Grades{2}=' PE ';
Grades{3}='PP-PE';
Grades{4}=' PP1 ';
Grades{5}=' PP2 ';

for i=1:5
    rectangle('Position',[i1(i),0,dt,100],'EdgeColor','y','LineStyle','-','LineWidth', 2);
    text(i1(i)-120,108,Grades{i})
end
ylim([0 200]);grid on;

for i=1:numel(StateNames)
    plot(d(:,1),d(:,iState(i)),Style{i},'DisplayName',StateNames{i})
end
legend
xlabel('Time(s)');ylabel('Process state per legend')

for i=1:numel(Grades)
    % Create and position figure
    figure(2);clf;
    set(gcf, 'Position', [100, 100, 1200, 500]);

    % Create indices to data of interest & handle movie plotting option
    iiData=find((d(:,1)>=i1(i))&(d(:,1)<=i2(i)));
    iiPNGs=find((FileTimes>=i1(i))&(FileTimes<=i2(i)));
    if bSaveMovie
        outputVideo=VideoWriter([Grades{i} '.avi'],'Uncompressed AVI');
        outputVideo.FrameRate=20;
        open(outputVideo);
    else
        iiPNGs=iiPNGs(end);
    end

    for j=1:length(iiPNGs)
        % Create plot of pressures
        figure(2);clf;
        subplot(1,4,1);hold on;
        plot(d(iiData,1),d(iiData,iState(3)),Style{3},'DisplayName',StateNames{3})
        plot(d(iiData,1),d(iiData,iState(4)),Style{4},'DisplayName',StateNames{4})
        iFrame=FileTimes(iiPNGs(j));
        plot([d(iFrame,1) d(iFrame,1)],[0 80],'k--','DisplayName','Image')
        legend('location','north');grid on;
        xlabel('Time, s');ylabel('Pressure, bar')
    
        % Load and show image at end
        subplot(1, 5, [2:5]);
        img=imread([PNGFolder AllFiles(iiPNGs(j)).name]);
        imshow(img);
        title(Grades{i})

        % Write frame to video if desired
        if bSaveMovie
            frame = getframe(gcf);
            writeVideo(outputVideo,frame);
        end
    end

    % Close video if use
    if bSaveMovie
        close(outputVideo);
    end

    i
    pause
end


