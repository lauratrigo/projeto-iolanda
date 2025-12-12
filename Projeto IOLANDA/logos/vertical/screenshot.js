const puppeteer = require('puppeteer');
const path = require('path');

(async () => {
  const browser = await puppeteer.launch({
    headless: "new" // Para funcionar com versões mais novas do Chromium
  });

  const page = await browser.newPage();

  // Caminho absoluto para seu arquivo index.html
  const filePath = path.resolve(__dirname, 'index.html');
  const fileUrl = `file://${filePath}`;

  // Carrega o arquivo HTML
  await page.goto(fileUrl, { waitUntil: 'networkidle0' });

  // Define a resolução da captura (ajuste conforme seu layout)
  await page.setViewport({ width: 1920, height: 1080 });

  // Aguarda carregamento de fontes e imagens
  await new Promise(resolve => setTimeout(resolve, 1000));

  // Tira a screenshot da página inteira
  await page.screenshot({
    path: 'logo.png',
    fullPage: true,
    omitBackground: false // use true se quiser fundo transparente
  });

  await browser.close();
  console.log('✅ Logo salvo como logo.png');
})();
