function arquivos = encontrarArquivosEstacao(pastaBase, codigoEstacao)
% ENCONTRARARQUIVOSESTACAO Encontra arquivos de uma estação específica
%   pastaBase: pasta raiz com as estações
%   codigoEstacao: SJC, JAT ou ARA
%   arquivos: estrutura com informações dos arquivos

    arquivos = [];
    
    % Caminho da estação
    pastaEstacao = fullfile(pastaBase, codigoEstacao);
    
    if ~isfolder(pastaEstacao)
        warning('Pasta da estação não encontrada: %s', pastaEstacao);
        return;
    end
    
    % Procura recursivamente por arquivos da estação
    arquivosEncontrados = dir(fullfile(pastaEstacao, '**', ['*.' codigoEstacao]));
    
    for i = 1:length(arquivosEncontrados)
        arquivo = arquivosEncontrados(i);
        caminhoCompleto = fullfile(arquivo.folder, arquivo.name);
        
        % Pula arquivos de filtro
        if contains(arquivo.name, 'Filtro', 'IgnoreCase', true)
            continue;
        end
        
        % Extrai informações da estrutura de pastas
        [ano, mes, dia] = extrairInfoDaEstrutura(arquivo.folder, codigoEstacao);
        
        arquivos = [arquivos, struct(...
            'caminho', caminhoCompleto, ...
            'nome', arquivo.name, ...
            'ano', ano, ...
            'mes', mes, ...
            'dia', dia ...
        )];
    end
end

function [ano, mes, dia] = extrairInfoDaEstrutura(caminhoPasta, codigoEstacao)
% EXTRAIRINFODAESTRUTURA Extrai ano, mês e dia da estrutura de pastas

    ano = '';
    mes = '';
    dia = '';
    
    try
        partes = strsplit(caminhoPasta, filesep);
        
        % Procura por padrões na estrutura
        for i = 1:length(partes)
            parte = partes{i};
            
            % Ano (4 dígitos)
            if length(parte) == 4 && all(isstrprop(parte, 'digit'))
                ano = parte;
                
            % Mês (padrão "YYYY MM")
            elseif contains(parte, ' ') && length(parte) == 7
                partesData = strsplit(parte, ' ');
                if length(partesData) == 2
                    ano = partesData{1};
                    mes = partesData{2};
                end
                
            % Dia (padrão YYMMDDSS)
            elseif length(parte) == 8 && all(isstrprop(parte(1:6), 'digit'))
                ano = ['20' parte(1:2)];
                mes = parte(3:4);
                dia = parte(5:6);
            end
        end
        
    catch
        % Em caso de erro, manter vazio
    end
end