context("Test multisynth for unbalanced panels")

set.seed(1011)

library(Synth)
data(basque)
basque <- basque %>% mutate(trt = case_when((regionno == 17) & (year >= 1975) ~ 1,
                                              (regionno == 16) & (year >= 1980) ~ 1,
                                              TRUE ~ 0)) %>%
      filter(regionno != 1)
regions <- basque %>% distinct(regionno) %>% pull(regionno)


test_that("Data formatting creates NAs correctly", {

  # drop a time period for unit 17
  basque %>%
    filter(regionno != 17 | year != 1970) -> basque_mis

  dat_format <- format_data_stag(quo(gdpcap), quo(trt),
                                  quo(regionno), quo(year), basque_mis)

  expect_true(is.na(dat_format$X[regions == 17, "1970"]))
})


test_that("Non-NA donors are chosen correctly", {

  # drop a time period for unit 17
  basque %>%
    filter(!regionno %in% c(15, 17, 18) | year != 1970) -> basque_mis

  dat_format <- format_data_stag(quo(gdpcap), quo(trt),
                                  quo(regionno), quo(year), basque_mis)
  donors <- get_nona_donors(dat_format$X, dat_format$trt, dat_format$mask, F)

  expect_true(!all(donors[[1]][regions %in% c(15, 17, 18) ]))
  expect_true(all(donors[[1]][!regions %in% c(15, 17, 18) ]))
  expect_true(all(donors[[2]]))
})

test_that("Separate synth with missing treated unit time drops the time", {

  # drop a time period for unit 17
  basque %>%
    filter(!regionno %in% c(17) | year != 1970) -> basque_mis
  
  msyn <- multisynth(gdpcap ~ trt, regionno, year, basque_mis, 
                     nu = 0, scm=T, eps_rel=1e-8, eps_abs=1e-8)

  msyn2 <- multisynth(gdpcap ~ trt, regionno, year, 
                      basque %>% filter(year != 1970),
                      nu = 0, scm=T, eps_rel=1e-8, eps_abs=1e-8)


  expect_equal(msyn$weights[,2], msyn2$weights[,2], tolderance = 1e-6)
})


test_that("Separate synth with missing control unit time drops control unit", {

  # drop a time period for unit 17
  basque %>%
    filter(!regionno %in% c(18) | year != 1970) -> basque_mis
  
  msyn <- multisynth(gdpcap ~ trt, regionno, year, basque_mis, 
                     nu = 0, scm=T, eps_rel=1e-8, eps_abs=1e-8)

  msyn2 <- multisynth(gdpcap ~ trt, regionno, year, 
                      basque %>% filter(regionno != 18),
                      nu = 0, scm=T, eps_rel=1e-8, eps_abs=1e-8)

  expect_equal(msyn$weights[-17,2], msyn2$weights[,2], tolerance = 1e-6)
})


test_that("Multisynth with unbalanced panels runs", {

  # drop a time period for unit 17
  basque %>%
    filter(!regionno %in% c(15, 17) | year != 1970) -> basque_mis

  msyn <- multisynth(gdpcap ~ trt, regionno, year, basque_mis, 
                     scm=T, eps_rel=1e-8, eps_abs=1e-8)

  expect_error(summary(msyn), NA)
})