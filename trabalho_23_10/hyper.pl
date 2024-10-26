% Conhecimento de fundo para os predicados odd e even
backliteral(even(L), [L:list], []).
backliteral(odd(L), [L:list], []).

% Definição de termo para lista
term(list, [X|L], [X:item, L:list]).
term(list, [], []).

% Cláusulas de partida para os predicados odd e even
start_clause(odd(L), []) / [L:list].
start_clause(even(L), []) / [L:list].

% Exemplos positivos (ex/1) para orientar o aprendizado
ex(even([])).           % Lista vazia é par
ex(even([a, b])).       % Lista com 2 elementos é par
ex(odd([a])).           % Lista com 1 elemento é ímpar
ex(odd([a, b, c])).     % Lista com 3 elementos é ímpar
ex(even([a, b, c, d])). % Lista com 4 elementos é par
ex(odd([a, b, c, d, e])). % Lista com 5 elementos é ímpar

% Exemplos negativos (nex/1) para orientação do aprendizado
nex(even([a])).         % Lista com 1 elemento não é par
nex(even([a, b, c])).   % Lista com 3 elementos não é par
nex(odd([])).           % Lista vazia não é ímpar
nex(odd([a, b, c, d])). % Lista com 4 elementos não é ímpar

:- induce.