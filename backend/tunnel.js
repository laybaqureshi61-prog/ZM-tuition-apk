const localtunnel = require('localtunnel');

async function startTunnel() {
  try {
    const tunnel = await localtunnel({ port: 5000 });
    console.log(`[TUNNEL ACTIVE] Public HTTPS URL: ${tunnel.url}`);
    
    tunnel.on('close', () => {
      console.log('[TUNNEL] Closed. Reconnecting in 3s...');
      setTimeout(startTunnel, 3000);
    });

    tunnel.on('error', (err) => {
      console.error('[TUNNEL ERROR]', err.message);
      tunnel.close();
    });
  } catch (err) {
    console.error('[TUNNEL INIT FAILED]', err.message);
    setTimeout(startTunnel, 5000);
  }
}

startTunnel();
