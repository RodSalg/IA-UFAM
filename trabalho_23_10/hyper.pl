%---------------------------------------------------------
% Program HYPER (Hypothesis Refiner) for learning in logic

:- op(500, xfx, :).

%---------------------------------------------------------
% Conhecimento de fundo para os predicados odd e even
backliteral(even(L), [L:list], []).
backliteral(odd(L), [L:list], []).

% Definição de termo para lista
term(list, [X|L], [X:item, L:list]).
term(list, [], []).

%---------------------------------------------------------
% Definição do predicado induce/1 para iniciar o processo de aprendizado
induce(Hyp) :-
    init_counts, % Inicializa os contadores
    start_hyps(Hyps), % Gera as hipóteses iniciais
    best_search(Hyps, _:Hyp), % Realiza a busca para encontrar a hipótese final
    !. % Impede backtracking após encontrar a solução

%---------------------------------------------------------
% Exemplos positivos (ex/1) para orientar o aprendizado
ex(even([])).           % Lista vazia é par
ex(even([a, b])).       % Lista com 2 elementos é par
ex(odd([a])).           % Lista com 1 elemento é ímpar
ex(odd([a, b, c])).     % Lista com 3 elementos é ímpar
ex(even([a, b, c, d])). % Lista com 4 elementos é par
ex(odd([a, b, c, d, e])). % Lista com 5 elementos é ímpar

% Exemplos negativos (nex/1) para orientar o aprendizado
nex(even([a])).         % Lista com 1 elemento não é par
nex(even([a, b, c])).   % Lista com 3 elementos não é par
nex(odd([])).           % Lista vazia não é ímpar
nex(odd([a, b, c, d])). % Lista com 4 elementos não é ímpar

%---------------------------------------------------------
% Predicados do HYPER

% Define as cláusulas iniciais para os predicados odd e even
% Definição do predicado start_clause/1 para os predicados odd e even
start_clause(even([])). % Define que a lista vazia é par
start_clause(even([_ | _]) :- false). % Define que uma lista não vazia não é par

start_clause(odd([_ | _])). % Define que uma lista com pelo menos um elemento é ímpar
start_clause(odd([]) :- false). % Define que uma lista não vazia não é ímpar


% Função para iniciar as hipóteses
start_hyps(Hyps) :-
    max_clauses(M),
    setof(C:H, (
        start_hyp(H0, M), add1(generated),
        complete(H0), add1(complete), eval(H, C)),
        Hyps).

% Cria uma hipótese inicial com até MaxClauses cláusulas
start_hyp([], _).
start_hyp([C | Cs], M) :-
    M > 0, M1 is M - 1,
    start_clause(C),
    start_hyp(Cs, M1).

% Busca a melhor hipótese
best_search([Hyp | _], Hyp) :-
    show_counts,
    Hyp = 0:_H,
    write('Hipótese completa encontrada'), nl,
    complete(H).

best_search([C0:H0 | Hyps0], H) :-
    write('Refinando hipótese com custo '), write(C0), nl,
    show_hyp(H0), nl,
    all_refinements(H0, NewHs),
    add_hyps(NewHs, Hyps0, Hyps), !,
    add1(refined),
    best_search(Hyps, H).

% Gera todos os refinamentos de uma hipótese
all_refinements(H0, Hyps) :-
    findall(C:H, (
        refine_hyp(H0, H),
        once((add1(generated),
              complete(H),
              add1(complete),
              eval(H, C))
             )), Hyps).

% Verifica se a hipótese cobre todos os exemplos positivos
complete(Hyp) :-
    \+ (ex(P),
        once(prove(P, Hyp, Answ)),
        Answ \== yes,
        write('Falhou ao provar: '), write(P), nl).


% Avalia o custo de uma hipótese
eval(Hyp, Cost) :-
    size(Hyp, Size),
    covers_neg(Hyp, N),
    Cost is Size + 10*N.

% Calcula o tamanho da hipótese
size([], 0).
size([CSo/Vs0 | RestHyp], Size) :-
    length(CSo, L0),
    length(Vs0, N0),
    size(RestHyp, SizeRest),
    Size is 10*L0 + N0 + SizeRest.

% Conta o número de exemplos negativos cobertos pela hipótese
covers_neg(Hyp, N) :-
    findall(1, (nex(E), once(prove(E, Hyp, Answ)), Answ \== no), L),
    length(L, N).

% Refina a hipótese
refine_hyp(Hyp0, Hyp) :-
    choose_clause(Hyp0, Clause0/Vars0, Clause1, Clauses1),
    conc(Clauses1, [Clause/Vars | Clauses2], Hyp),
    refine(Clause0, Vars0, Clause, Vars).

choose_clause(Hyp, Clause, Clauses1, Clauses2) :-
    conc(Clauses1, [Clause | Clauses2], Hyp).

% Refina a cláusula unificando argumentos
refine(Clause, Args, Clause, NewArgs) :-
    conc(Args1, [A | Args2], Args),
    member(A, Args2),
    conc(Args1, Args2, NewArgs).

% Refina a cláusula adicionando um literal
refine(Clause, Args, NewClause, NewArgs) :-
    length(Clause, L),
    max_clause_length(MaxL),
    L < MaxL,
    backliteral(Lit, InArgs, RestArgs),
    conc(Clause, [Lit], NewClause),
    connect_inputs(Args, InArgs),
    conc(Args, RestArgs, NewArgs).

% Prova um objetivo com base na hipótese fornecida
prove(even([]), _, yes) :- !.  % Caso especial: a lista vazia é par
prove(odd([_ | _]), _, yes) :- !. % Caso especial: lista com pelo menos um elemento é ímpar
prove(Goal, Hypo, yes) :-
    member(Clause/Vars, Hypo),
    copy_term(Clause, [Head | Body]),
    Goal = Head,
    prove_body(Body, Hypo).
prove(_, _, no).


% Prova o corpo de uma cláusula
prove_body([], _).
prove_body([G | Gs], Hypo) :-
    prove(G, Hypo, yes),
    prove_body(Gs, Hypo).

% Funções auxiliares para manipulação de listas e contadores
conc([], L, L).
conc([X | T], L, [X | L1]) :-
    conc(T, L, L1).

init_counts :-
    retract(counter(_, _)), fail.
init_counts :-
    assert(counter(generated, 0)),
    assert(counter(complete, 0)),
    assert(counter(refined, 0)).

add1(Counter) :-
    retract(counter(Counter, N)), !, N1 is N+1,
    assert(counter(Counter, N1)).

show_counts :-
    counter(generated, NG), counter(refined, NR), counter(complete, NC),
    nl, write('Hypotheses generated: '), write(NG),
    nl, write('Hypotheses refined: '), write(NR),
    nl, write('To be refined: '), write(NG - NR),
    nl, write('Complete: '), write(NC), nl.

% Configuração dos parâmetros
max_proof_length(15).
max_clauses(6).      
max_clause_length(6).


%---------------------------------------------------------
% Comando para iniciar o processo de aprendizado
:- induce(Hypothesis),
   write('Hipótese final aprendida: '), nl,
   show_hyp(Hypothesis).

%---------------------------------------------------------
% Funções para exibir a hipótese
show_hyp([C/Vars | Cs]) :- nl,
    copy_term(C/Vars, C1/Vars1),
    name_vars(Vars1, ['A','B','C','D','E','F','G','H','I','J','K','L','M','N']),
    show_clause(C1),
    show_hyp(Cs).

show_clause([Head | Body]) :-
    write(Head), 
    (Body = [] -> write('.'), nl;
     write(' :- '), nl,
     write_body(Body)).

write_body([G | Gs]) :-
    tab(2), write(G),
    (Gs = [] -> write('.'), nl;
     write(','), nl,
     write_body(Gs)).

name_vars([], []).
name_vars([Name:Type | Xs], [Name | Names]) :-
    name_vars(Xs, Names).
