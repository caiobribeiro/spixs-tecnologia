# Spec: Implementar Tela de Avaliação de Professor

## Context
O aluno precisa poder avaliar o professor após cada aula. A tela deve coletar nota (1-5), comentário opcional e data da avaliação.

## Requirements
- O aluno seleciona uma aula passada na lista.
- Ao selecionar, abre um formulário com:
  - Slider de 1 a 5 estrelas
  - Campo de texto para comentário (opcional)
  - Botão "Enviar Avaliação"
- Após envio, exibe feedback de sucesso ou erro.
- As avaliações são salvas no banco via RPC `create_teacher_evaluation`.

## Constraints
- Seguir Clean Architecture: Presentation → Domain → Data.
- Usar Result Pattern para tratamento de erros.
- Usar Command Pattern para o botão de submit.
- Verificar se o RPC `create_teacher_evaluation` existe antes de implementar.

## Scope
### In Scope
- Tela de avaliação (view + viewmodel)
- Integração com RPC existente
- Validação do formulário

### Out of Scope
- Listar avaliações anteriores
- Editar avaliação existente
- Notificações push

## Acceptance Criteria
1. Slider exibe 5 estrelas e permite selecionar nota entre 1 e 5.
2. Campo de comentário é opcional e aceita até 500 caracteres.
3. Ao enviar, o Command executa a chamada RPC e atualiza o estado UI.
4. Em caso de erro, exibe snackbar com mensagem apropriada.
5. O formulário só permite submissão quando uma nota está selecionada.
