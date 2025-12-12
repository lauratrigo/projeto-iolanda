function corrigirHorariosFaltantes(arquivoEntrada, arquivoSaida)
    fid = fopen(arquivoEntrada, 'r');
    cabecalho = fgetl(fid);
    dados = textscan(fid, '%s %s %s %s %s %s', ...
                     'Delimiter', ' ', 'MultipleDelimsAsOne', true);
    fclose(fid);

    % Extrai e converte dados
    dataStr = dados{1};
    dddStr  = dados{2};
    horaStr = dados{3};
    foF2str = dados{4};
    hFstr   = dados{5};
    hpF2str = dados{6};

    foF2 = str2double(foF2str);
    hF   = str2double(hFstr);
    hpF2 = str2double(hpF2str);

    timestamp = datetime(strcat(dataStr, {' '}, horaStr), 'InputFormat', 'yyyy.MM.dd HH:mm:ss');

    % Cria grade fixa 00:00 -> 23:55
    dataUnica = datetime(dataStr{1}, 'InputFormat', 'yyyy.MM.dd');
    grade = (dataUnica:minutes(5):dataUnica+hours(23)+minutes(55))';

    % Inicializa colunas
    foF2_full = nan(size(grade));
    hF_full   = nan(size(grade));
    hpF2_full = nan(size(grade));

    [~, idx] = ismember(timestamp, grade);
    for i = 1:length(idx)
        if idx(i) ~= 0
            if ~isnan(foF2(i)), foF2_full(idx(i)) = foF2(i); end
            if ~isnan(hF(i)),   hF_full(idx(i))   = hF(i);   end
            if ~isnan(hpF2(i)), hpF2_full(idx(i)) = hpF2(i); end
        end
    end

    % Salva arquivo corrigido
    fid = fopen(arquivoSaida, 'w');
    fprintf(fid, "%s\n", cabecalho);
    for i = 1:length(grade)
        fprintf(fid, '%s %s %s  %.3f   %.1f   %.1f\n', ...
                datestr(grade(i), 'yyyy.mm.dd'), dddStr{1}, datestr(grade(i),'HH:MM:ss'), ...
                foF2_full(i), hF_full(i), hpF2_full(i));
    end
    fclose(fid);
end
