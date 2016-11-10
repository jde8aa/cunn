#ifndef THC_GENERIC_FILE
#define THC_GENERIC_FILE "generic/MarginCriterion.cu"
#else

void THNN_(MarginCriterion_updateOutput)(
           THCState *state,
           THCTensor *input,
           THCTensor *target,
           THCTensor *output,
           bool sizeAverage,
           real margin)
{
  THCUNN_assertSameGPU_generic(state, 2, input, target);

  long size = THCTensor_(nElement)(state, input);

  input = THCTensor_(newContiguous)(state, input);
  target = THCTensor_(newContiguous)(state, target);

  thrust::device_ptr<real> input_data(THCTensor_(data)(state, input));
  thrust::device_ptr<real> target_data(THCTensor_(data)(state, target));
  accreal sum = thrust::inner_product(input_data, input_data+size, target_data, (accreal) 0, thrust::plus<accreal>(),
      margin_functor<real, accreal>(ScalarConvert<real, accreal>::to(margin)));

  if (sizeAverage)
    sum /= size;

  THCTensor_(free)(state, input);
  THCTensor_(free)(state, target);

  THCTensor_(set1d)(state, output, 0, ScalarConvert<accreal, real>::to(sum));
}


void THNN_(MarginCriterion_updateGradInput)(
           THCState *state,
           THCTensor *input,
           THCTensor *target,
           THCTensor *gradInput,
           bool sizeAverage,
           real margin)
{
  THCUNN_assertSameGPU_generic(state, 3, input, target, gradInput);

  long size = THCTensor_(nElement)(state, input);
  accreal norm = sizeAverage ? 1.f/size : 1;

  input = THCTensor_(newContiguous)(state, input);
  target = THCTensor_(newContiguous)(state, target);

  THCTensor_(resizeAs)(state, gradInput, input);

  thrust::device_ptr<real> input_data(THCTensor_(data)(state, input));
  thrust::device_ptr<real> target_data(THCTensor_(data)(state, target));
  thrust::device_ptr<real> gradInput_data(THCTensor_(data)(state, gradInput));

  thrust::transform(input_data, input_data+size, target_data, gradInput_data,
      margin_updateGradInput_functor<real, accreal>(ScalarConvert<real, accreal>::to(margin), norm));

  THCTensor_(free)(state, input);
  THCTensor_(free)(state, target);
}

#endif