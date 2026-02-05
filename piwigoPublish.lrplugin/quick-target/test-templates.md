# Test & Benchmark Templates - Plan d'Optimisation

## Template 1 : Benchmark Pre/Post Étape

```lua
-- TestHarness.lua - À utiliser pour chaque étape

local Benchmark = {}

function Benchmark.start(testName)
    return {
        name = testName,
        startTime = os.time(),
        startMemory = collectgarbage("count"),
        events = {}
    }
end

function Benchmark.mark(session, markerName)
    table.insert(session.events, {
        marker = markerName,
        time = os.time(),
        memory = collectgarbage("count")
    })
end

function Benchmark.finish(session)
    local endTime = os.time()
    local endMemory = collectgarbage("count")
    
    local report = {
        name = session.name,
        totalTime = endTime - session.startTime,
        memoryDelta = endMemory - session.startMemory,
        events = session.events
    }
    
    return report
end

function Benchmark.print(report)
    log:info(string.format(
        "BENCHMARK: %s | Time: %ds | Memory: %dKB | Events: %d",
        report.name,
        report.totalTime,
        report.memoryDelta,
        #report.events
    ))
    
    for _, event in ipairs(report.events) do
        log:info(string.format("  → %s: +%ds, %dKB",
            event.marker,
            event.time - session.startTime,
            event.memory
        ))
    end
end
```

**Utilisation** :
```lua
-- Avant Étape 1A
local sessionBefore = Benchmark.start("Publication 50 photos - BEFORE 1A")
-- ... simulation publication 50 photos ...
Benchmark.mark(sessionBefore, "getAllCategories")
Benchmark.mark(sessionBefore, "tagsToIds")
-- ... etc ...
local reportBefore = Benchmark.finish(sessionBefore)

-- Après Étape 1A (avec CacheManager)
local sessionAfter = Benchmark.start("Publication 50 photos - AFTER 1A")
-- ... same test ...
local reportAfter = Benchmark.finish(sessionAfter)

-- Comparaison
log:info(string.format("GAIN: %.1f%% faster",
    ((reportBefore.totalTime - reportAfter.totalTime) / reportBefore.totalTime) * 100
))
```

---

## Template 2 : Checklist de Régression Post-Étape

### Étape 1A : CacheManager

**Test : Publication simple 1 photo**
- [ ] Photo uploads to Piwigo
- [ ] Metadata sent correctly
- [ ] URL stored in Lightroom (pwImageURL)
- [ ] No extra HTTP calls (use log filtering)

**Test : Publication 2e fois (cache should hit)**
- [ ] First getAllCategories() = 1 API call
- [ ] Second getAllCategories() = 0 API calls (cache)
- [ ] Verify cache TTL respected (600s)
- [ ] Log shows "cache hit" on 2nd call

**Test : Cache invalidation**
- [ ] Change Piwigo host → cache clears
- [ ] Change credentials → cache clears
- [ ] Manual cache clear works (if UI button added)

**Test : Large publication (100+ photos)**
- [ ] Memory usage stable (not growing)
- [ ] No timeout on getAllCategories
- [ ] All photos upload successfully

---

### Étape 1B : Batch Metadata

**Test : Metadata queue fills & flushes**
- [ ] Photos uploaded 1-10 → queued in photosMetadataQueue
- [ ] At 10 photos → batchUpdateMetadata() called
- [ ] Queue resets after batch
- [ ] Remaining photos < 10 → flushed after loop

**Test : Metadata correctness**
- [ ] Compare metadata sent in batch vs individual
- [ ] Should be identical (same fields, same values)
- [ ] Keywords, synonyms, dates all correct

**Test : API call reduction**
- [ ] Count API calls (filter logs for "method")
- [ ] BEFORE: 50 photos = ~150 API calls (upload + metadata)
- [ ] AFTER: 50 photos = ~60 API calls (upload + 5 batch metadata)
- [ ] Gain: -60% metadata calls

---

### Étape 2A : Streaming Data

**Test : Memory tracking**
- [ ] Baseline: Load all categories in memory
  - Measure memory before/after getAllCategories()
- [ ] Streaming version: Process one category at a time
  - Measure same before/after
- [ ] Should see -75% peak memory

**Test : Correctness of streaming**
- [ ] Built index (pwIndexByPath, pwIndexById) identical
- [ ] No categories skipped
- [ ] Hierarchy preserved

**Test : Large album structures (1000+ categories)**
- [ ] BEFORE: Timeout or crash risk (OOM)
- [ ] AFTER: Completes smoothly < 30s

---

### Étape 2B : ConnectionPool

**Test : Connection reuse**
- [ ] First login → creates connection, stores in pool
- [ ] getAllCategories() → reuses pool connection
- [ ] getAllTags() → reuses pool connection
- [ ] Log should show "reusing connection" not "logging in"

**Test : Connection lifecycle**
- [ ] After 10 min idle → connection marked invalid
- [ ] Next call → new login (pool detects dead connection)
- [ ] Old reconnection logic (resetConnectioncount) removed

**Test : Multiple services (if supported)**
- [ ] Service A uses connection pool A
- [ ] Service B uses connection pool B
- [ ] No cross-contamination

---

### Étape 3A : URL Cache Index

**Test : Existing photo detection**
- [ ] Photo1 published to Album1
- [ ] pwImageURL stored in photo metadata
- [ ] Publish same photo to Album2
- [ ] Instead of upload → use `associateImageToCategory()`
- [ ] Verify association happened (log message + no duplicate)

**Test : Performance (100 photos, 50 already published)**
- [ ] BEFORE: 100 lookups = 2-5 seconds
- [ ] AFTER: O(1) lookups = < 0.2 seconds
- [ ] Gain: -95%

**Test : Multi-album edge cases**
- [ ] Photo published to A → detect via URL
- [ ] Try publish to B → associate
- [ ] Try publish to C → reuse cached index
- [ ] All 3 albums show photo

**Test : Cache invalidation**
- [ ] Change host/credentials → index clears
- [ ] Photo deleted from pwMetadata → re-upload next time

---

### Étape 4A : Async Render/Upload

**Test : Overlap**
- [ ] Monitor CPU and network simultaneously
- [ ] BEFORE: CPU busy (100%) then idle, then CPU again (sequential)
- [ ] AFTER: CPU ~70%, network active during CPU time (overlap)

**Test : Render queue**
- [ ] 50 photos → all initiate renders
- [ ] Start collecting renders as they finish
- [ ] Upload starts while others still render

**Test : No corruption**
- [ ] Final images identical (exact same bytes)
- [ ] Metadata identical
- [ ] No partial uploads or corrupted files

**Test : Timing**
- [ ] BEFORE: 50 photos = 12 minutes
- [ ] AFTER: 50 photos = 7 minutes (est.)
- [ ] Gain: -40%

---

### Étape 5B : Lazy Tag Loading

**Test : First load (cache empty)**
- [ ] Call getAllTags() → makes API call
- [ ] Takes ~1-2 seconds (network)
- [ ] Saves to disk cache

**Test : Subsequent loads (cache hit)**
- [ ] Call getAllTags() again → loads from disk
- [ ] Takes < 50ms (instant)
- [ ] No API call (log should show 0 API calls)

**Test : Cache TTL**
- [ ] Cache valid for 1 hour
- [ ] After 1 hour → API call (cache expired)
- [ ] Manual refresh button works

**Test : Tag indexing**
- [ ] 500+ tags on Piwigo
- [ ] tagsToIdsOptimized() builds index
- [ ] Lookup for each tag = O(1)
- [ ] BEFORE: 2-3 seconds for all tags
- [ ] AFTER: 0.05 seconds

**Test : Missing tags detection**
- [ ] New tag in Lightroom (not on Piwigo)
- [ ] Identified as missingTags
- [ ] Created on Piwigo during upload
- [ ] Cache invalidates after creation

---

## Template 3 : Full Integration Test (Post-Phase)

```lua
-- IntegrationTest.lua

function IntegrationTest.fullPublicationCycle()
    local testPhotos = {
        {file = "test1.jpg", album = "Album A", tags = "sunset,beach"},
        {file = "test2.jpg", album = "Album A", tags = "sunset"},
        {file = "test3.jpg", album = "Album B", tags = "beach,nature"},
    }
    
    -- Phase 1 : Initial upload
    local session = Benchmark.start("Full cycle - initial upload")
    
    for _, photo in ipairs(testPhotos) do
        publishPhoto(photo)
    end
    
    Benchmark.mark(session, "initial-upload-done")
    
    -- Phase 2 : Re-publish (multi-album detection)
    testPhotos[1].album = "Album B"  -- Move to different album
    publishPhoto(testPhotos[1])
    
    Benchmark.mark(session, "multi-album-done")
    
    -- Phase 3 : Metadata update only
    testPhotos[1].tags = "sunset,beach,golden"
    syncMetadataOnly(testPhotos[1])
    
    Benchmark.mark(session, "metadata-sync-done")
    
    local report = Benchmark.finish(session)
    Benchmark.print(report)
    
    -- Assertions
    assert(#PWStatusManager.pendingPhotos == 0, "Pending photos should be empty")
    assert(PWStatusManager.lastErrorCount == 0, "No errors should occur")
end
```

---

## Template 4 : Performance Report (Fill After Validation)

```markdown
## Étape [X.Y] - [Nom] - Performance Report

### Métriques Observées

| Métrique | Avant | Après | Delta | % Gain |
|----------|-------|-------|-------|--------|
| Publication 50 photos | [X] min | [Y] min | [Z] min | [%] % |
| API calls | [A] | [B] | [C] | [%] % |
| Memory peak | [D] MB | [E] MB | [F] MB | [%] % |
| Tags lookup (500 tags) | [G] sec | [H] sec | [I] sec | [%] % |

### Tests Passants
- [X] Regression tests (all passed)
- [X] Backward compatibility (no breaking changes)
- [X] Edge cases (empty, large, null inputs)
- [X] Error handling (timeout, network down, auth fail)

### Issues Découvertes
- [None | List any issues found]

### Actions Avant Merge
- [ ] Code review self-check
- [ ] Commit message clear
- [ ] No debug logs left
- [ ] Update CHANGELOG if public release

### Prêt pour Phase Suivante ?
✅ YES | ⏳ Attendre [blocker] | ❌ Rollback à [previous state]
```

