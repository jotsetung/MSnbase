############################################################
## Compare the "conventional" constructor with the C implementation
ints <- as.numeric(1:1000)
mzs <- as.numeric(1:1000)

############################################################
## Spectrum1.
test_that("Spectrum1 constructor", {
    Res1 <- new("Spectrum1", intensity = ints, mz = mzs, polarity = 1L,
                rt = 12.4, fromFile = 3L, tic = 1234.3, centroided = TRUE)
    Res2 <- MSnbase:::Spectrum1(intensity = ints, mz = mzs, polarity = 1L,
                                rt = 12.4, fromFile = 3L, tic = 1234.3,
                                centroided = TRUE)
    expect_identical(Res1, Res2)
    ## Test exception, i.e. mz specified but not intensity or vice versa.
    expect_error(Test <- MSnbase:::Spectrum1(intensity = ints, polarity = 1L,
                                             rt = 12.4, fromFile = 3L,
                                             tic = 1234.3, centroided = TRUE))
    expect_error(Test <- MSnbase:::Spectrum1(mz = mzs, polarity = 1L, rt = 12.4,
                                             fromFile = 3L, tic = 1234.3,
                                             centroided = TRUE))
    expect_identical(classVersion(Res1)["Spectrum1"],
                     new("Versions",
                         Spectrum1 = MSnbase:::getClassVersionString("Spectrum1")))
    expect_identical(classVersion(Res1)["Spectrum"],
                     new("Versions",
                         Spectrum = MSnbase:::getClassVersionString("Spectrum")))
    ## Check empty spectrum
    expect_true(validObject(MSnbase:::Spectrum1()))

    ## Check new slots
    res1 <- new("Spectrum1", intensity = ints, mz = mzs, metadata = list(a = 4),
                peakAnnotations = data.frame(pk = 1, name = "a"), polarity = 1L)
    res2 <- MSnbase:::Spectrum1(intensity = ints, mz = mzs,
                                metadata = list(a = 4), polarity = 1L,
                                peakAnnotations = data.frame(pk = 1, name = "a"))
    expect_equal(res1, res2)
})

test_that("M/Z sorted Spectrum1 constructor", {
    set.seed(123)
    mzVals <- abs(rnorm(3500, mean = 100, sd = 10))
    intVals <- abs(rnorm(3500, mean = 10, sd = 5))

    ##sorted <- MSnbase:::sortNumeric(mzVals)
    ##idx <- MSnbase:::orderNumeric(mzVals)
    ## expect_identical(idx, order(mzVals))
    sorted <- sort(mzVals)
    idx <- order(mzVals)
    ## R constructor:
    sp1 <- new("Spectrum1", intensity = intVals, mz = mzVals,
               polarity = 1L, fromFile = 1L, rt = 13.3, tic = 1234.3)
    ## unsorted C-constructor:
    sp2 <- MSnbase:::Spectrum1(intensity = intVals, mz = mzVals,
                               polarity = 1L, fromFile = 1L, rt = 13.3,
                               tic = 1234.3)
    expect_identical(mz(sp1), sort(mz(sp2)))
    ## C-constructor with sorting:
    sp3 <- MSnbase:::Spectrum1_mz_sorted(intensity = intVals, mz = mzVals,
                                         polarity = 1L, fromFile = 1L,
                                         rt = 13.3, tic = 1234.3)
    expect_identical(mz(sp3), sort(mzVals))
    expect_identical(intensity(sp3), intVals[idx])
    expect_identical(sp3, sp1)
    expect_identical(classVersion(sp3)["Spectrum1"],
                     new("Versions",
                         Spectrum1 = MSnbase:::getClassVersionString("Spectrum1")))
    expect_identical(classVersion(sp3)["Spectrum"],
                     new("Versions",
                         Spectrum = MSnbase:::getClassVersionString("Spectrum")))
    ## Check empty spectrum
    expect_true(validObject(MSnbase:::Spectrum1_mz_sorted()))

    ## Check new slots
    res1 <- new("Spectrum1", intensity = intVals, mz = mzVals,
                metadata = list(a = 4),
                peakAnnotations = data.frame(pk = 1, name = "a"), polarity = 1L)
    res2 <- MSnbase:::Spectrum1_mz_sorted(
                          intensity = intVals, mz = mzVals,
                          metadata = list(a = 4), polarity = 1L,
                          peakAnnotations = data.frame(pk = 1, name = "a"))
    expect_equal(res1, res2)
})

## Test the c-level multi-Spectrum1 constructor with M/Z ordering.
## o Ensure that ordering is as expected.
## o Check that the Spectrum values are as expected.
## o Check that classVersions are properly set.
test_that("C-level multi-Spectrum1 constructor with M/Z ordering", {
    ## Use Spectra1_mz_sorted constructor.
    set.seed(123)
    mzVals <- abs(rnorm(20000, mean = 10, sd = 10))
    intVals <- abs(rnorm(20000, mean = 1000, sd = 1000))
    rts <- c(1.3, 1.4, 1.5, 1.6)
    acqN <- 1:4
    nvals <- rep(5000, 4)

    mzValsList <- split(mzVals, f = rep(1:4, each = 5000))
    intValsList <- split(intVals, f = rep(1:4, each = 5000))
    idxList <- lapply(mzValsList, order)

    ## Switch on gctorture to force potential memory mapping problems.
    ## gctorture(on = TRUE)
    spectL <- MSnbase:::Spectra1_mz_sorted(rt = rts, acquisitionNum = acqN,
                                           scanIndex = acqN, mz = mzVals,
                                           intensity = intVals,
                                           tic = rep(0, length(nvals)),
                                           fromFile = rep(1, 4),
                                           polarity = rep(1L, 4),
                                           nvalues = nvals)
    ## gctorture(on = FALSE)
    expect_true(all(unlist(lapply(spectL, validObject))))
    ## Check the TIC: should be the sum of intensities
    ticL <- lapply(intValsList, sum)
    expect_equal(unname(unlist(ticL)),
                 unname(unlist(lapply(spectL, tic))))
    ## Check the class version for one of the spectra:
    expect_identical(classVersion(spectL[[3]])["Spectrum1"],
                     new("Versions",
                         Spectrum1 = MSnbase:::getClassVersionString("Spectrum1")))
    expect_identical(classVersion(spectL[[1]])["Spectrum"],
                     new("Versions",
                         Spectrum = MSnbase:::getClassVersionString("Spectrum")))
    ##gctorture(on = TRUE)
    spectL <- MSnbase:::Spectra1_mz_sorted(rt = rts, acquisitionNum = acqN,
                                           scanIndex = acqN, mz = mzVals,
                                           intensity = intVals,
                                           fromFile = rep(1, 4),
                                           polarity = rep(1L, 4),
                                           nvalues = nvals,
                                           tic = rep(12, 4))
    ## gctorture(on = FALSE)
    expect_true(all(unlist(lapply(spectL, validObject))))
    expect_equal(rep(12, 4),
                 unname(unlist(lapply(spectL, tic))))
    expect_identical(classVersion(spectL[[3]])["Spectrum1"],
                     new("Versions",
                         Spectrum1 = MSnbase:::getClassVersionString("Spectrum1")))
    expect_identical(classVersion(spectL[[1]])["Spectrum"],
                     new("Versions",
                         Spectrum = MSnbase:::getClassVersionString("Spectrum")))
    ## Check if we've got the M/Z and intensity values correctly sorted.
    for (i in 1:length(idxList)) {
        expect_identical(mz(spectL[[i]]), mzValsList[[i]][idxList[[i]]])
        expect_identical(intensity(spectL[[i]]), intValsList[[i]][idxList[[i]]])
    }

    spectL <- MSnbase:::Spectra1_mz_sorted(rt = rts, acquisitionNum = acqN,
                                           scanIndex = acqN, mz = mzVals,
                                           intensity = intVals,
                                           tic = rep(0, length(nvals)),
                                           fromFile = rep(1, 4),
                                           polarity = rep(1L, 4),
                                           nvalues = nvals,
                                           metadata = list(list(name = "a"),
                                                           list(name = "b"),
                                                           list(name = "c"),
                                                           list(name = "b")))
    expect_equal(spectL[[1]]@metadata, list(name = "a"))
    expect_equal(spectL[[2]]@metadata, list(name = "b"))
    expect_equal(spectL[[3]]@metadata, list(name = "c"))
    expect_equal(spectL[[4]]@metadata, list(name = "b"))

    dfs <- list(data.frame(name = 1:5), data.frame(), data.frame(name = 8:10),
                data.frame(name = 1:3, bla = "other"))
    spectL <- MSnbase:::Spectra1_mz_sorted(rt = rts, acquisitionNum = acqN,
                                           scanIndex = acqN, mz = mzVals,
                                           intensity = intVals,
                                           tic = rep(0, length(nvals)),
                                           fromFile = rep(1, 4),
                                           polarity = rep(1L, 4),
                                           nvalues = nvals,
                                           peakAnnotations = dfs)
    expect_equal(spectL[[1]]@peakAnnotations, dfs[[1]])
    expect_equal(spectL[[2]]@peakAnnotations, dfs[[2]])
    expect_equal(spectL[[3]]@peakAnnotations, dfs[[3]])
    expect_equal(spectL[[4]]@peakAnnotations, dfs[[4]])

    ## Check empty spectra.
    ## Spectrum1
    mzVals <- sort(abs(rnorm(200, mean = 100, sd = 10)))
    intVals <- abs(rnorm(200, mean = 10, sd = 5))
    nVals <- c(50, 0, 0, 20, 0, 100, 0, 30, 0)
    rts <- c(1, 2, 3, 4, 5, 6, 7, 8, 9)
    res <- MSnbase:::Spectra1_mz_sorted(rt = rts,
                                        acquisitionNum = 1:length(nVals),
                                        mz = mzVals, intensity = intVals,
                                        nvalues = nVals)
    expect_equal(length(res), length(nVals))
    expect_equal(length(mz(res[[2]])), 0)
    expect_equal(length(mz(res[[4]])), 20)
    expect_equal(mz(res[[4]]), mzVals[51:70])
    expect_true(all(unlist(lapply(res, validObject))))

    ## If nVals does NOT match mz
    nVals_err <- c(50, 0, 0, 20, 0, 100, 0, 30, 4)
    expect_error(MSnbase:::Spectra1_mz_sorted(rt = rts,
                                              acquisitionNum = 1:length(nVals),
                                              mz = mzVals, intensity = intVals,
                                              nvalues = nVals_err))
})


############################################################
## Spectrum2.

## M/Z sorted Spectrum2 constructor.
test_that("M/Z sorted Spectrum2 constructor", {
    set.seed(123)
    mzVals <- abs(rnorm(3500, mean = 100, sd = 10))
    intVals <- abs(rnorm(3500, mean = 10, sd = 5))

    sorted <- sort(mzVals)
    idx <- order(mzVals)
    ## R constructor:
    system.time(
        sp1 <- new("Spectrum2", intensity = intVals, mz = mzVals,
                   polarity = -1L, fromFile = 1L, rt = 13.3, tic = 1234.3)
    ) ## 0.004
    expect_identical(mz(sp1), sort(mzVals))
    expect_identical(intensity(sp1), intVals[idx])
    ## Check other slot values...
    expect_identical(sp1@polarity, -1L)
    expect_identical(sp1@fromFile, 1L)
    expect_identical(sp1@rt, 13.3)
    expect_identical(sp1@tic, 1234.3)
    ## Check class versions
    expect_identical(classVersion(sp1)["Spectrum2"],
                     new("Versions",
                         Spectrum2 = MSnbase:::getClassVersionString("Spectrum2")))
    expect_identical(classVersion(sp1)["Spectrum"],
                     new("Versions",
                         Spectrum = MSnbase:::getClassVersionString("Spectrum")))
    ## C-constructor with sorting:
    sp2 <- MSnbase:::Spectrum2_mz_sorted(intensity = intVals, mz = mzVals,
                                         polarity = -1L, fromFile = 1L,
                                         rt = 13.3, tic = 1234.3)
    expect_identical(mz(sp2), sort(mzVals))
    expect_identical(intensity(sp2), intVals[idx])
    ## Check class versions
    expect_identical(classVersion(sp2)["Spectrum2"],
                     new("Versions",
                         Spectrum2 = MSnbase:::getClassVersionString("Spectrum2")))
    expect_identical(classVersion(sp2)["Spectrum"],
                     new("Versions",
                         Spectrum = MSnbase:::getClassVersionString("Spectrum")))

    ## Calculate tic within:
    sp1 <- new("Spectrum2", intensity = intVals, mz = mzVals)
    expect_equal(sp1@tic, sum(intVals))
    ## Test some exceptions...
    ## o Pass only intensity or mz
    expect_error(new("Spectrum2", intensity = intVals, polarity = 1L))
    expect_error(new("Spectrum2", mz = muVals, polarity = 1L))

    ## Check empty spectrum
    expect_true(validObject(MSnbase:::Spectrum2()))
    expect_true(validObject(MSnbase:::Spectrum2_mz_sorted()))

    ## metadata and peakAnnotations
    sp1 <- new("Spectrum2", intensity = intVals, mz = mzVals,
               polarity = -1L, metadata = list(name = "a"))
    sp2 <- MSnbase:::Spectrum2_mz_sorted(intensity = intVals, mz = mzVals,
                                         polarity = -1L,
                                         metadata = list(name = "a"))
    expect_equal(sp1@metadata, sp2@metadata)

    sp1 <- new("Spectrum2", intensity = intVals, mz = mzVals,
               polarity = -1L, peakAnnotations = data.frame(name = "a",
                                                            value = 1:5))
    sp2 <- MSnbase:::Spectrum2_mz_sorted(
                         intensity = intVals, mz = mzVals, polarity = -1L,
                         peakAnnotations = data.frame(name = "a", value = 1:5))
    expect_equal(sp1@peakAnnotations, sp2@peakAnnotations)
})

## Test the c-level multi-Spectrum2 constructor with M/Z ordering.
## o Ensure that ordering is as expected.
## o Check that the Spectrum values are as expected.
test_that("C-level multi-Spectrum2 constructor with M/Z ordering", {
    ## Use Spectra2_mz_sorted constructor.
    set.seed(123)
    mzVals <- abs(rnorm(20000, mean = 10, sd = 10))
    intVals <- abs(rnorm(20000, mean = 1000, sd = 1000))
    rts <- c(1.3, 1.4, 1.5, 1.6)
    acqN <- 1:4
    nvals <- rep(5000, 4)

    mzValsList <- split(mzVals, f = rep(1:4, each = 5000))
    intValsList <- split(intVals, f = rep(1:4, each = 5000))
    idxList <- lapply(mzValsList, order)

    ## gctorture(on = TRUE)
    spectL <- MSnbase:::Spectra2_mz_sorted(rt = rts, acquisitionNum = acqN,
                                           scanIndex = acqN, mz = mzVals,
                                           intensity = intVals,
                                           fromFile = rep(1, 4),
                                           polarity = rep(1L, 4),
                                           nvalues = nvals,
                                           msLevel = rep(2, length(nvals)),
                                           tic = rep(0, length(nvals)))
    ## gctorture(on = FALSE)
    expect_true(all(unlist(lapply(spectL, validObject))))
    ## Check the TIC: should be the sum of intensities
    ticL <- lapply(intValsList, sum)
    expect_equal(unname(unlist(ticL)),
                 unname(unlist(lapply(spectL, tic))))
    ## Check class versions
    expect_identical(classVersion(spectL[[1]])["Spectrum2"],
                     new("Versions",
                         Spectrum2 = MSnbase:::getClassVersionString("Spectrum2")))
    expect_identical(classVersion(spectL[[3]])["Spectrum"],
                     new("Versions",
                         Spectrum = MSnbase:::getClassVersionString("Spectrum")))
    ## gctorture(on = TRUE)
    spectL <- MSnbase:::Spectra2_mz_sorted(rt = rts, acquisitionNum = acqN,
                                           scanIndex = acqN, mz = mzVals,
                                           intensity = intVals,
                                           fromFile = rep(1, 4),
                                           polarity = rep(1L, 4),
                                           nvalues = nvals,
                                           tic = rep(12, 4),
                                           msLevel = rep(2, 4))
    expect_true(all(unlist(lapply(spectL, validObject))))
    expect_equal(rep(12, 4),
                 unname(unlist(lapply(spectL, tic))))
    ## Check class versions
    expect_identical(classVersion(spectL[[1]])["Spectrum2"],
                     new("Versions",
                         Spectrum2 = MSnbase:::getClassVersionString("Spectrum2")))
    expect_identical(classVersion(spectL[[3]])["Spectrum"],
                     new("Versions",
                         Spectrum = MSnbase:::getClassVersionString("Spectrum")))

    ## Check if we've got the M/Z and intensity values correctly sorted.
    for (i in 1:length(idxList)) {
        expect_identical(mz(spectL[[i]]), mzValsList[[i]][idxList[[i]]])
        expect_identical(intensity(spectL[[i]]), intValsList[[i]][idxList[[i]]])
    }

    ## Spectrum2
    mzVals <- sort(abs(rnorm(200, mean = 100, sd = 10)))
    intVals <- abs(rnorm(200, mean = 10, sd = 5))
    nVals <- c(50, 0, 0, 20, 0, 100, 0, 30, 0)
    rts <- c(1, 2, 3, 4, 5, 6, 7, 8, 9)
    res <- MSnbase:::Spectra2_mz_sorted(rt = rts,
                                        acquisitionNum = 1:length(nVals),
                                        mz = mzVals, intensity = intVals,
                                        nvalues = nVals,
                                        msLevel = rep(2, length(nVals)))
    expect_equal(length(res), length(nVals))
    expect_equal(length(mz(res[[2]])), 0)
    expect_equal(length(mz(res[[4]])), 20)
    expect_equal(mz(res[[4]]), mzVals[51:70])
    expect_error(MSnbase:::Spectra2_mz_sorted(rt = rts,
                                              acquisitionNum = 1:length(nVals),
                                              mz = mzVals, intensity = intVals,
                                              nvalues = nVals_err))
    ## metadata
    res <- MSnbase:::Spectra2_mz_sorted(rt = rts,
                                        acquisitionNum = 1:length(nVals),
                                        mz = mzVals, intensity = intVals,
                                        nvalues = nVals,
                                        msLevel = rep(2, length(nVals)),
                                        metadata = list(list(a = 1),
                                                        list(b = 2),
                                                        list(c = 4),
                                                        list(a = 4),
                                                        list(b = 2),
                                                        list(a = 4),
                                                        list(b = 2),
                                                        list(z = 5),
                                                        list(e = 3)))
    expect_equal(res[[4]]@metadata, list(a = 4))
    expect_equal(res[[9]]@metadata, list(e = 3))
    ## peakAnnotations
    res <- MSnbase:::Spectra2_mz_sorted(
                         rt = rts,
                         acquisitionNum = 1:length(nVals), mz = mzVals,
                         intensity = intVals, nvalues = nVals,
                         msLevel = rep(2, length(nVals)),
                         peakAnnotations = list(data.frame(a = 1),
                                                data.frame(b = 2),
                                                data.frame(c = 4),
                                                data.frame(a = 4),
                                                data.frame(b = 2),
                                                data.frame(a = 4),
                                                data.frame(b = 2),
                                                data.frame(z = 5),
                                                data.frame(e = 3)))
    expect_equal(res[[4]]@peakAnnotations, data.frame(a = 4))
    expect_equal(res[[9]]@peakAnnotations, data.frame(e = 3))
})
