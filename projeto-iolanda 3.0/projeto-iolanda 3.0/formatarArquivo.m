function linhasFormatadas = formatarArquivo(caminhoArquivo)

    % Abrir arquivo
    fid = fopen(caminhoArquivo, 'r');
    if fid == -1
        error('Não foi possível abrir o arquivo: %s', caminhoArquivo);
    end

    % Pular as duas primeiras linhas
    fgetl(fid); % Redutor:
    fgetl(fid); % Data:

    % Ler o restante das linhas
    linhas = textscan(fid, '%s', 'Delimiter', '\n');
    fclose(fid);
    linhas = linhas{1};

    % Extrair dia do nome do arquivo (ex: 2017H02F.txt -> 02)
    [~, nomeArquivo, ~] = fileparts(caminhoArquivo);
    token = regexp(nomeArquivo, 'H(\d{2})F', 'tokens');
    if isempty(token)
        error('Nome de arquivo inválido: %s', nomeArquivo);
    end
    dia = str2double(token{1}{1});
    dataBase = datetime(2017, 8, dia);
    diaJuliano = day(dataBase, 'dayofyear');

    % Inicializar saída
    linhasFormatadas = {};

    for i = 1:length(linhas)
        linha = strtrim(linhas{i});
        if isempty(linha)
            continue;
        end

        dados = regexp(linha, '\s+', 'split');

        if length(dados) < 5
            continue;
        end

        % Extrair e converter
        UT = str2double(strrep(dados{1}, ',', '.'));
        if isnan(UT)
            continue; % pula linha inválida
        end

        minutosTotal = round(UT * 60);
        hora = floor(minutosTotal / 60);
        minuto = mod(minutosTotal, 60);
        tempoStr = sprintf('%02d:%02d:00', hora, minuto);

        foF2  = str2double(strrep(dados{4}, ',', '.'));
        hF    = str2double(strrep(dados{3}, ',', '.'));
        hpF2  = str2double(strrep(dados{5}, ',', '.'));

        s_foF2 = formatarCampo(foF2, '%.3f');
        s_hF   = formatarCampo(hF,   '%.1f');
        s_hpF2 = formatarCampo(hpF2, '%.1f');

        linhaFormatada = sprintf('%04d.%02d.%02d (%03d) %s   %6s   %7s   %7s', ...
        year(dataBase), month(dataBase), day(dataBase), ...
        diaJuliano, tempoStr, s_foF2, s_hF, s_hpF2);

        linhasFormatadas{end+1} = linhaFormatada;
    end
end

function s = formatarCampo(valor, formato)
    if isnan(valor)
        s = 'NaN';
    else
        s = sprintf(formato, valor);
    end
end
