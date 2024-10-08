% A means-ends planner with goal regression
% plan(State, Goals, Plan) é verdadeiro se Plan é uma sequência de ações que transforma State em um estado que satisfaz Goals.
% Caso base: se os Goals já estão satisfeitos no State atual, o Plan é vazio.
plan(State, Goals, []) :-
    satisfied(State, Goals),
    writeln('Goals satisfied').  % Mensagem de depuração para indicar que os objetivos foram satisfeitos.

% Caso recursivo: constrói um plano de ações.
plan(State, Goals, Plan) :-
    append(PrePlan, [Action], Plan),  % Divide o plano em um prefixo PrePlan e uma última ação Action.
    writeln(selecting_goal(Goals)),   % Mensagem de depuração para indicar que um objetivo está sendo selecionado.
    select_goal(Goals, Goal),         % Seleciona um objetivo (Goal) a ser alcançado.
    writeln(goal_selected(Goal)),     % Mensagem de depuração para indicar qual objetivo foi selecionado.
    achieves(Action, Goal),           % Verifica se a ação (Action) alcança o objetivo (Goal).
    writeln(action_achieves(Action, Goal)),  % Mensagem de depuração para indicar que a ação alcança o objetivo.
    can(Action, Condition),           % Verifica se a ação pode ser realizada sob certas condições.
    writeln(action_can(Action, Condition)),  % Mensagem de depuração para indicar que a ação pode ser realizada.
    preserves(Action, Goals),         % Verifica se a ação não destrói nenhum dos objetivos.
    writeln(action_preserves(Action, Goals)), % Mensagem de depuração para indicar que a ação preserva os objetivos.
    regress(Goals, Action, RegressedGoals),  % Regride os objetivos através da ação.
    writeln(plan(State, RegressedGoals, PrePlan)),  % Mensagem de depuração para indicar o plano em construção.
    plan(State, RegressedGoals, PrePlan).  % Recursivamente planeja para os objetivos regredidos.

% -----------------------------------------------------------------------
% satisfied(State, Goals) é verdadeiro se todos os Goals estão presentes no State.
satisfied(State, Goals) :-
    delete_all(Goals, State, []).  % Remove todos os Goals do State, e verifica se o resultado é uma lista vazia.

% -----------------------------------------------------------------------
% select_goal(Goals, Goal) é verdadeiro se Goal é um membro de Goals.
select_goal(Goals, Goal) :-
    member(Goal, Goals).

% -----------------------------------------------------------------------
% achieves(Action, Goal) é verdadeiro se a Action adiciona o Goal.
achieves(Action, Goal) :-
    adds(Action, Goals),  % Obtém as relações adicionadas pela Action.
    member(Goal, Goals).  % Verifica se o Goal está entre as relações adicionadas.

% -----------------------------------------------------------------------
% preserves(Action, Goals) é verdadeiro se a Action não remove nenhum dos Goals.
preserves(Action, Goals) :-
    deletes(Action, Relations),  % Obtém as relações removidas pela Action.
    \+ (member(Goal, Relations), member(Goal, Goals)).  % Verifica se nenhum Goal está entre as relações removidas.

% -----------------------------------------------------------------------
% regress(Goals, Action, RegressedGoals) regride os Goals através da Action.
regress(Goals, Action, RegressedGoals) :-
    adds(Action, NewRelations),  % Obtém as relações adicionadas pela Action.
    delete_all(Goals, NewRelations, RestGoals),  % Remove as relações adicionadas dos Goals.
    can(Action, Condition),  % Obtém as condições sob as quais a Action pode ser realizada.
    addnew(Condition, RestGoals, RegressedGoals).  % Adiciona novas condições aos Goals restantes.

% -----------------------------------------------------------------------
% addnew(NewGoals, OldGoals, AllGoals): AllGoals é a união de NewGoals e OldGoals, garantindo compatibilidade.
addnew([], L, L).
addnew([Goal | _], Goals, _) :-
    impossible(Goal, Goals),  % Verifica se Goal é incompatível com Goals.
    !, fail.  % Falha se for impossível adicionar Goal.
addnew([X | L1], L2, L3) :-
    member(X, L2), !,  % Ignora duplicatas.
    addnew(L1, L2, L3).
addnew([X | L1], L2, [X | L3]) :-
    addnew(L1, L2, L3).

% -----------------------------------------------------------------------
% delete_all(L1, L2, Diff): Diff é a diferença de conjuntos entre L1 e L2.
delete_all([], _, []).
delete_all([X | L1], L2, Diff) :-
    member(X, L2), !,
    delete_all(L1, L2, Diff).
delete_all([X | L1], L2, [X | Diff]) :-
    delete_all(L1, L2, Diff).

% --------------------------------------------------------------------------------------------------
% Definições de ações permitidas.
% --------------------------------------------------------------------------------------------------
% can(Action, Condition) define as condições necessárias para realizar uma ação.
can(move(Block, From, To), [clear(Block), clear(To), on(Block, From), safe_to_stack(From, To)]) :-
    block(Block),
    object(To),
    To \== Block,
    object(From),
    From \== To,
    Block \== From.

% --------------------------------------------------------------------------------------------------
% Efeitos das ações (adição e remoção de relações).
% --------------------------------------------------------------------------------------------------
% adds(Action, Relations) define as relações adicionadas por uma ação.
adds(move(X, From, To), [on(X, To), clear(From)]).

% deletes(Action, Relations) define as relações removidas por uma ação.
deletes(move(X, From, To), [on(X, From), clear(To)]).

% --------------------------------------------------------------------------------------------------
% Definições de blocos e objetos.
% --------------------------------------------------------------------------------------------------
% Definições de blocos.
block(a).
block(b).
block(c).
block(d).

% Definição de objeto.
object(table).

% --------------------------------------------------------------------------------------------------
% Definição de predicados auxiliares.
% --------------------------------------------------------------------------------------------------
% impossible(Goal, Goals) é verdadeiro se Goal é incompatível com Goals.
impossible(X, Goals) :-
    member(X, Goals),
    fail.
impossible(_, _).