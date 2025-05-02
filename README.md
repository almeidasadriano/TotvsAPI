<h2>Sobre</h2>
<blockquote>
  <p dir="auto">Criação de API do Protheus para inclusão de Pré-Nota de Entrada, utilizando  <b>MSExecAuto MATA140</b></p>
</blockquote>

<b>Importante:</b>  Estou executando o ExecAuto mas antes tem um Prepare Enviroment com a filial e empresa, por dentro do Protheus esse ExecAuto funciona normalmente porém no caso da API, ele não reconhece a filial setada apenas no cabeçalho.

##  Tecnologias
<div>
  <p><img src="https://img.shields.io/badge/Protheus-ADVPL-blue?logo=totvs&logoColor=%23999999"></p>
  <p><img src="https://img.shields.io/badge/Protheus-API-darkgreen?logo=totvs&logoColor=%23999999"></p>
</div>

// Utiliza a inclusão automática de pré-nota de entrada
<div class="snippet-clipboard-content notranslate position-relative overflow-auto" data-snippet-clipboard-copy-content="MSExecAuto({|x, y, z| MATA140(x, y, z)}, aCabec, aItens, 3)">

  <pre class="notranslate">
      <code>  
             MSExecAuto({|x, y, z| MATA140(x, y, z)}, aCabec, aItens, 3)
      </code>
  </pre>
  
</div>
