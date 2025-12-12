function resultados = processa_arquivos(filenames, ax)
% PROCESSA_ARQUIVOS - Calcula e plota h'F, f0F2 e hmF2
% filenames : cell array com caminhos dos arquivos TXT
% ax        : handle do UIAxes onde os gráficos serão plotados
% resultados: struct com médias e desvios

num_stations = length(filenames);

all_hF = [];
all_foF2 = [];
all_hmF2 = [];

for station_idx = 1:num_stations
    filename = filenames{station_idx};

    fileID = fopen(filename,'r');
    if fileID == -1
        warning('Erro ao abrir arquivo: %s', filename);
        continue;
    end

    data = textscan(fileID,'%s %s %s %f %f %f','HeaderLines',1,...
        'Delimiter',' ','MultipleDelimsAsOne',true);
    fclose(fileID);

    date_str = data{1};
    time_str = data{3};
    foF2 = data{4};
    hF   = data{5};
    hmF2 = data{6};

    datetime_str = strcat(date_str, {' '}, time_str);
    time = datetime(datetime_str,'InputFormat','yyyy.MM.dd HH:mm:ss');

    if numel(time) > 1
        dt = diff(time);
        passo_min = mode(minutes(dt));
    else
        passo_min = 5;
    end

    start_time = min(time);
    end_time   = max(time);
    full_time = (start_time:minutes(passo_min):end_time)';

    full_hF   = NaN(size(full_time));
    full_foF2 = NaN(size(full_time));
    full_hmF2 = NaN(size(full_time));

    [~, ia, ib] = intersect(full_time, time);
    full_hF(ia)   = hF(ib);
    full_foF2(ia) = foF2(ib);
    full_hmF2(ia) = hmF2(ib);

    all_hF(:,station_idx)   = full_hF;
    all_foF2(:,station_idx) = full_foF2;
    all_hmF2(:,station_idx) = full_hmF2;
end

% Cálculos de médias e desvios
N = size(all_hF,1);

mediahF   = smooth(nanmean(all_hF,2),36,'moving');
desviohF  = nanstd(all_hF,0,2);
mediaf0F2 = smooth(nanmean(all_foF2,2),36,'moving');
desviof0F2= nanstd(all_foF2,0,2);
mediahmF2 = smooth(nanmean(all_hmF2,2),36,'moving');
desviohmF2= nanstd(all_hmF2,0,2);

% --- Plotagem ---
if nargin < 2 || isempty(ax)
    figure;
    ax = gobjects(3,1);
    ax(1) = subplot(3,1,1);
    ax(2) = subplot(3,1,2);
    ax(3) = subplot(3,1,3);
end

tempo = 1:N;
grayColor = [0.7,0.7,0.7];

cla(ax(1)); hold(ax(1),'on');
plot(ax(1), tempo, mediahF, 'LineWidth', 3);
errorbar(ax(1), tempo, mediahF, desviohF, 'Color', grayColor);
ylabel(ax(1), 'h''F (Km)');

cla(ax(2)); hold(ax(2),'on');
plot(ax(2), tempo, mediaf0F2, 'LineWidth', 3);
errorbar(ax(2), tempo, mediaf0F2, desviof0F2, 'Color', grayColor);
ylabel(ax(2), 'f0F2 (MHz)');

cla(ax(3)); hold(ax(3),'on');
plot(ax(3), tempo, mediahmF2, 'LineWidth', 3);
errorbar(ax(3), tempo, mediahmF2, desviohmF2, 'Color', grayColor);
ylabel(ax(3), 'hmF2 (Km)');

resultados = struct('mediahF', mediahF, 'desviohF', desviohF, ...
                    'mediaf0F2', mediaf0F2, 'desviof0F2', desviof0F2, ...
                    'mediahmF2', mediahmF2, 'desviohmF2', desviohmF2);
end
