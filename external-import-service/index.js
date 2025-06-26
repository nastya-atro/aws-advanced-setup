const { fork } = require('child_process');

const earthquake = fork('./child_processes/upload-earthquake.js');
// Rest processes can be added here

console.log('All child processes started');

earthquake.on('exit', (code) => {
  console.log(`upload-earthquake exited with code ${code}`);
});
