import files;
import string;
import sys;
import io;
import stats;
import python;
import math;
import location;
import assert;
import R;

import EQPy;

string emews_root = getenv("EMEWS_PROJECT_ROOT");
string turbine_output = getenv("TURBINE_OUTPUT");
string resident_work_ranks = getenv("RESIDENT_WORK_RANKS");
printf("resident_work_ranks: %i", resident_work_ranks);
string r_ranks[] = split(resident_work_ranks,",");
int max_evals = toint(argv("max_evals", "100"));
int param_batch_size = toint(argv("param_batch_size", "10"));

printf("PYTHONPATH: %s", getenv("PYTHONPATH"));

// this is the "model"
string template =
"""
import math

params = %s
a = math.sin(params['x'][0])
""";

// algorithm params format is a string representation
// of a python dictionary. eqpy_hyperopt evals this
// string to create the dictionary. This, unfortunately,
string algo_params_template =
"""
{'space' : %s,
'algo' : %s,
'max_evals' : %d,
'param_batch_size' : %d,
'seed' : %d}
""";

(string result) run_obj(string param_line, string id_suffix)
{
    // exmample of making instance dir if each run needs its own
    // working directory.
    string instance_dir = "%s/instance_%s/" % (turbine_output, id_suffix);
    make_dir(instance_dir) => {
      result = python(template % param_line, "str(a)");
      rm_dir(instance_dir);
    }
}

(string parameter_combos[]) create_parameter_combinations(string params, int trials) {
  // TODO
  // Given the parameter string and the number of trials for that
  // those parameters, create an array of parameter combinations
  // Typically, this involves at least appending a different random
  // seed to the parameter string for each trial
}

(string obj_result) obj(string params, int trials, string iter_indiv_id) {

    // Typical code might create multiple sets of parameters from a single
    // set by duplicating that set some number of times and appending a
    // different random seed to each of the new sets. The example doesn't
    // do that so we only need to run obj rather than create those new
    // parameters and iterate over them.
    // string parameter_combos[] = create_parameter_combinations(params, trials);
    // float fresults[];
    //foreach f,i in params {
    //    string id_suffix = "%s_%i" % (iter_indiv_id,i);
    //    fresults[i] = run_obj(f, id_suffix);
    //}
    string id_suffix = "%s_%i" % (iter_indiv_id,1);
    obj_result = run_obj(params, id_suffix);
}

(void v) loop (location ME, int ME_rank, int trials) {
    for (boolean b = true, int i = 1;
       b;
       b=c, i = i + 1)
  {
    // gets the model parameters from the python algorithm
    string params =  EQPy_get(ME);
    boolean c;
    // TODO
    // Edit the finished flag, if necessary.
    // when the python algorithm is finished it should
    // pass "DONE" into the queue, and then the
    // final set of parameters. If your python algorithm
    // passes something else then change "DONE" to that
    if (params == "FINAL")
    {
        string finals =  EQPy_get(ME);
        printf("Final Result: %s" % finals);
        // TODO if appropriate
        // split finals string and join with "\\n"
        // e.g. finals is a ";" separated string and we want each
        // element on its own line:
        // multi_line_finals = join(split(finals, ";"), "\\n");
        string fname = "%s/final_result_%i" % (turbine_output, ME_rank);
        file results_file <fname> = write(finals + "\n") =>
        printf("Writing final result to %s", fname) =>
        // printf("Results: %s", finals) =>
        v = make_void() =>
        c = false;
    }
    else
    {

        string param_array[] = split(params, ";");
        string results[];
        foreach p, j in param_array
        {
            results[j] = obj(p, trials, "%i_%i_%i" % (ME_rank,i,j));
        }

        string res = join(results, ",");
        EQPy_put(ME, res) => c = true;

    }
  }
}

// TODO
// Edit function arguments to include those passed from main function
// below
(void o) start (int ME_rank, int num_variations, int random_seed) {
    location ME = locationFromRank(ME_rank);
    // create the python dictionary representation of the
    // parameters for the hyperopt algorithm
    // see https://github.com/hyperopt/hyperopt/wiki/FMin#2-defining-a-search-space
    // for more info the search space
    string space = "hyperopt.hp.uniform(\\'x\\', -2, 2)";
    // this can also be hyperopt.tpe.suggest, but in that case
    // we might not get much parallelism.
    string algo = "hyperopt.rand.suggest";

    string algo_params = algo_params_template % (space, algo, max_evals,
      param_batch_size, random_seed);
    // python raises an error if we pass a multiline string using EQPy_put
    // so the \n are removed. algo_params_template is easier to read and edit
    // as a multiline string so I left it like that and fixed it here.
    string trimmed_algo_params = trim(replace_all(algo_params, "\n", " ", 0));

    printf("ME_rank: %i", ME_rank);
    EQPy_init_package(ME,"eqpy_hyperopt.hyperopt_runner") =>
    EQPy_get(ME) =>
    EQPy_put(ME, trimmed_algo_params) =>
      loop(ME, ME_rank, num_variations) => {
        EQPy_stop(ME);
        o = propagate();
      }
}

// deletes the specified directory
app (void o) rm_dir(string dirname) {
  "rm" "-rf" dirname;
}

// call this to create any required directories
app (void o) make_dir(string dirname) {
  "mkdir" "-p" dirname;
}

// anything that need to be done prior to a model runs
// (e.g. file creation) can be done here
//app (void o) run_prerequisites() {
//
//}


main() {

  // TODO
  // Retrieve arguments to this script here
  // these are typically used for initializing the python algorithm
  // Here, as an example, we retrieve the number of variations (i.e. trials)
  // for each model run, and the random seed for the python algorithm.
  int num_variations = toint(argv("nv", "1"));
  int random_seed = toint(argv("seed", "0"));

  printf("turbine_workers(): %i", turbine_workers());

  // PYTHONPATH needs to be set for python code to be run
  assert(strlen(getenv("PYTHONPATH")) > 0, "Set PYTHONPATH!");
  assert(strlen(emews_root) > 0, "Set EMEWS_PROJECT_ROOT!");

  int ME_ranks[];
  foreach r_rank, i in r_ranks{
    ME_ranks[i] = toint(r_rank);
  }

  //run_prerequisites() => {
    foreach ME_rank, i in ME_ranks {
      start(ME_rank, num_variations, random_seed);
    }
//}

}
