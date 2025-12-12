function fecharGraficos(fHandle)
    % Fecha a figura
    delete(fHandle);

    % Se não houver mais figuras abertas com gráficos, abre o programas()
    % Supondo que suas figuras de gráficos têm a Tag 'graficosIOLANDA'
    figs = findall(0, 'Type', 'figure', 'Tag', 'graficosIOLANDA');
    if isempty(figs)
        programas();  % Abre o GUI principal apenas se não houver mais figuras abertas
    end
end