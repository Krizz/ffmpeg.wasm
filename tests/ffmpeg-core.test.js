let core;

const genName = (name) => `[ffmpeg-core][${FFMPEG_TYPE}] ${name}`;

const reset = async () => {
  await core.reset();
  core.setLogger(() => {});
  core.setProgress(() => {});
};

before(async () => {
  core = await createCore();
  await core.FS.writeFile("video.mp4", b64ToUint8Array(VIDEO_1S_MP4));
});

describe(genName("createFFmpeg()"), () => {
  it("should be OK", () => {
    expect(core).to.be.ok;
  });
});

describe(genName("reset()"), () => {
  beforeEach(reset);

  it("should exist", () => {
    expect("reset" in core).to.be.true;
  });
  it("should reset ret and timeout", async () => {
    await core.set("ret", 1024);
    await core.set("timeout", 1024);

    await core.reset();

    expect(await core.get("ret")).to.equal(-1);
    expect(await core.get("timeout")).to.equal(-1);
  });
});

describe(genName("exec()"), () => {
  beforeEach(reset);

  it("should exist", () => {
    expect("exec" in core).to.be.true;
  });

  it("should output help", async () => {
    expect(await core.exec("-h")).to.equal(0);
  });

  it("should transcode", async () => {
    expect(await core.exec("-i", "video.mp4", "video.avi")).to.equal(0);
    const out = await core.FS.readFile("video.avi");
    expect(out.length).to.not.equal(0);
    await core.FS.unlink("video.avi");
  });
});

describe(genName("setTimeout()"), () => {
  beforeEach(reset);

  it("should exist", () => {
    expect("setTimeout" in core).to.be.true;
  });

  it("should timeout", async () => {
    await core.setTimeout(1); // timeout after 1ms
    expect(await core.exec("-i", "video.mp4", "video.avi")).to.equal(1);
  });
});

describe(genName("setLogger()"), () => {
  beforeEach(reset);

  it("should exist", () => {
    expect("setLogger" in core).to.be.true;
  });

  it("should handle logs", async () => {
    const logs = [];
    core.setLogger(({ message }) => logs.push(message));
    await core.exec("-h");
    expect(logs.length).to.not.equal(0);
  });
});

describe(genName("setProgress()"), () => {
  beforeEach(reset);

  it("should exist", () => {
    expect("setProgress" in core).to.be.true;
  });

  it("should handle progress", async () => {
    let progress = 0;
    core.setProgress(({ progress: _progress }) => (progress = _progress));
    expect(await core.exec("-i", "video.mp4", "video.avi")).to.equal(0);
    expect(progress).to.equal(1);
    await core.FS.unlink("video.avi");
  });
});
