r <- getOption("repos")
r["CRAN"] <- "http://cran.cnr.berkeley.edu/"
options(repos = r)

install.packages("rgenoud")
install.packages("DiceKriging")
install.packages("randomForest")
