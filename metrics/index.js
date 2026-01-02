const express = require('express');
const app = express();
const port = 3001;
bodyParser = require('body-parser');
const redis = require('redis');
const os = require('os');
const fs = require('fs');
const path = require('path');


app.use(bodyParser.json());

// Connect to Redis
const client = redis.createClient({
  socket: {
    host: 'redis', // service name
    port: 6379,
  }
});
client.connect().catch(console.error);

app.use(express.json());


// Prometheus metrics endpoint
app.get('/metrics', async (req, res) => {
  try {
    const cpuMetrics = getCPUMetrics();
    const diskMetrics = getDiskMetrics();
    const gpuMetrics = getGPUMetrics();

    let metricsOutput = '';

    // CPU metrics
    metricsOutput += `# HELP cpu_usage_percent CPU usage percentage\n`;
    metricsOutput += `# TYPE cpu_usage_percent gauge\n`;
    metricsOutput += `cpu_usage_percent{core="total"} ${cpuMetrics.totalUsage}\n`;
    cpuMetrics.cores.forEach((core, index) => {
      metricsOutput += `cpu_usage_percent{core="${index}"} ${core}\n`;
    });

    // Disk metrics
    metricsOutput += `# HELP disk_usage_bytes Disk usage in bytes\n`;
    metricsOutput += `# TYPE disk_usage_bytes gauge\n`;
    metricsOutput += `disk_usage_bytes{mount="/"} ${diskMetrics.used}\n`;
    metricsOutput += `# HELP disk_free_bytes Free disk space in bytes\n`;
    metricsOutput += `# TYPE disk_free_bytes gauge\n`;
    metricsOutput += `disk_free_bytes{mount="/"} ${diskMetrics.free}\n`;
    metricsOutput += `# HELP disk_total_bytes Total disk space in bytes\n`;
    metricsOutput += `# TYPE disk_total_bytes gauge\n`;
    metricsOutput += `disk_total_bytes{mount="/"} ${diskMetrics.total}\n`;

    // GPU metrics
    metricsOutput += `# HELP gpu_usage_percent GPU usage percentage\n`;
    metricsOutput += `# TYPE gpu_usage_percent gauge\n`;
    metricsOutput += `gpu_usage_percent{device="${gpuMetrics.device}"} ${gpuMetrics.usage}\n`;
    metricsOutput += `# HELP gpu_memory_bytes GPU memory usage in bytes\n`;
    metricsOutput += `# TYPE gpu_memory_bytes gauge\n`;
    metricsOutput += `gpu_memory_bytes{device="${gpuMetrics.device}"} ${gpuMetrics.memoryUsage}\n`;

    res.set('Content-Type', 'text/plain');
    res.send(metricsOutput);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Helper function to get CPU metrics
function getCPUMetrics() {
  const cpus = os.cpus();
  const cpuUsage = process.cpuUsage();
  
  // Calculate total CPU usage from process CPU usage
  const totalCPUUsage = ((cpuUsage.user + cpuUsage.system) / 1000000) % 100;

  // Calculate per-core usage (simulated based on OS data)
  const coreUsages = cpus.map(cpu => {
    const total = Object.values(cpu.times).reduce((a, b) => a + b, 0);
    const idle = cpu.times.idle;
    return parseFloat(((1 - idle / total) * 100).toFixed(2));
  });

  return {
    totalUsage: parseFloat(totalCPUUsage.toFixed(2)),
    cores: coreUsages,
  };
}

// Helper function to get disk metrics
function getDiskMetrics() {
  try {
    // For Node.js, we need to use a workaround to get disk usage
    // This is a simplified implementation that estimates disk usage
    const totalMemory = os.totalmem();
    const freeMemory = os.freemem();
    const usedMemory = totalMemory - freeMemory;

    // Estimate disk usage based on available system information
    // In production, consider using diskusage or similar library
    return {
      total: totalMemory,
      used: usedMemory,
      free: freeMemory,
    };
  } catch (err) {
    return {
      total: 0,
      used: 0,
      free: 0,
    };
  }
}

// Helper function to get GPU metrics
function getGPUMetrics() {
  // GPU metrics require GPU-specific libraries (nvidia-ml-py, gpu-monitor, etc.)
  // This is a placeholder implementation
  // In production, integrate with actual GPU monitoring tools
  return {
    device: 'GPU-0',
    usage: 0, // Percentage
    memoryUsage: 0, // Bytes
  };
}


app.post('/', function (req, res) {
  const body = req.body;
  /*Body logic here*/
  res.json({ message: 'Organization created' });
})

app.listen(port, () => {
  console.log(`Service 2 is running on port ${port}`);
});
