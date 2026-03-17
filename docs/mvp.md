# 📱 Documentação de Casos de Uso - MVP L&J Doces

---

**UC01: Consultar Cardápio Digital (Real-time)**

* **Ator Principal:** Cliente (Aluno/Funcionário da UNIFEOB).
* **Objetivo:** Visualizar doces disponíveis e preços em tempo real para verificação antes do deslocamento.
* **Pré-condições:** Aplicativo instalado e catálogo cadastrado pelo proprietário.
* **Pós-condições:** Cliente informado sobre a disponibilidade imediata dos produtos.

---

* **Fluxo Principal:**
    1. O cliente abre o aplicativo L&J Doces.
    2. O sistema carrega o catálogo sincronizado em tempo real via Firebase.
    3. O sistema exibe o nome, preço e a disponibilidade dos doces.

---

* **Fluxos Alternativos:**
    * **A1 (Modo Offline):** O sistema carrega os dados salvos localmente caso não haja conexão.
    * **A2 (Produto Esgotado):** O item é atualizado no catálogo em até 2 segundos após zerar no estoque.

---

**UC02: Registrar Venda e Baixa de Estoque**

* **Ator Principal:** Proprietário (L&J Doces).
* **Objetivo:** Registrar a saída de produtos, atualizar estoque e gerenciar o lucro real.
* **Pré-condições:** Login administrativo realizado no módulo de gestão.
* **Pós-condições:** Estoque reduzido e venda salva no histórico financeiro da empresa.

---

* **Fluxo Principal:**
    1. O proprietário acessa a área de gestão de vendas.
    2. Seleciona o doce vendido da lista de produtos.
    3. Escolhe a forma de pagamento, incluindo o registro de "Penduricalhos".
    4. Confirma a transação e o sistema abate a unidade do estoque automaticamente.

---

* **Fluxos Alternativos:**
    * **A1 (Registro de Penduricalho):** O proprietário vincula a venda ao sistema de registro de dívidas a prazo.
    * **A2 (Alerta Crítico):** O sistema emite um alerta automático se o estoque atingir o nível mínimo definido.

---

**UC03: Gerenciar Catálogo (CRUD)**

* **Ator Principal:** Proprietário (L&J Doces).
* **Objetivo:** Manter a lista de produtos (sabores, preços e estoque) sempre atualizada.
* **Pré-condições:** Acesso administrativo autenticado.
* **Pós-condições:** O catálogo público é atualizado para todos os clientes em tempo real.

---

* **Fluxo Principal:**
    1. O proprietário seleciona a opção de cadastro de produtos.
    2. Escolhe entre as ações de cadastrar, editar ou excluir item.
    3. Altera os dados necessários (preço, sabor, estoque) e salva as modificações.
